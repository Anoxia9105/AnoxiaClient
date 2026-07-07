import 'dart:async';
import 'dart:convert';

import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/provider/live/live_room_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';

enum LiveVisibility {
  public,
  private;

  String get label => this == LiveVisibility.public ? '公开' : '私密';
}

extension LiveVisibilityCodec on LiveVisibility {
  String get serverValue {
    switch (this) {
      case LiveVisibility.public:
        return 'PUBLIC';
      case LiveVisibility.private:
        return 'PRIVATE';
    }
  }
}

enum LiveSource {
  camera,
  screen;

  String get label => this == LiveSource.camera ? '摄像头' : '屏幕共享';
}

extension LiveSourceCodec on LiveSource {
  String get serverValue {
    switch (this) {
      case LiveSource.camera:
        return 'CAMERA';
      case LiveSource.screen:
        return 'SCREEN';
    }
  }
}

class LiveRoomPage extends ConsumerStatefulWidget {
  final String roomId;
  final String title;
  final bool isHost;
  final LiveVisibility visibility;
  final LiveSource source;
  final String? screenSourceId;

  const LiveRoomPage({
    super.key,
    required this.roomId,
    this.title = '',
    required this.isHost,
    this.visibility = LiveVisibility.public,
    this.source = LiveSource.camera,
    this.screenSourceId,
  });

  @override
  ConsumerState<LiveRoomPage> createState() => _LiveRoomPageState();
}

class _LiveRoomPageState extends ConsumerState<LiveRoomPage> {
  static const _danmakuTopic = 'live-danmaku';
  static const _cohostRequestTopic = 'live-cohost-request';
  static const _cohostResponseTopic = 'live-cohost-response';

  final TextEditingController _chatController = TextEditingController();
  final List<_LiveChatMessage> _messages = [
    const _LiveChatMessage(text: '欢迎进入直播间，开始互动吧', isHost: true, name: '系统'),
  ];
  final Map<String, _CohostRequest> _cohostRequests = {};

  EventsListener<RoomEvent>? _roomListener;
  Room? _listeningRoom;
  bool _cohostRequested = false;
  bool _cohostActive = false;
  bool _initialMediaStarted = false;
  bool _joinMessageSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enterRoom();
    });
  }

  @override
  void dispose() {
    _roomListener?.dispose();
    _chatController.dispose();
    if (widget.isHost) {
      unawaited(_endLive());
    }
    super.dispose();
  }

  Future<void> _enterRoom() async {
    if (widget.isHost) {
      final mic = await Permission.microphone.request();
      final camera = widget.source == LiveSource.camera
          ? await Permission.camera.request()
          : null;
      if (!mic.isGranted || (camera != null && !camera.isGranted)) {
        if (!mounted) return;
        Toast.showNotificationNow(
          widget.source == LiveSource.camera ? '需要开启摄像头和麦克风权限' : '需要开启麦克风权限',
        );
        Navigator.of(context).pop();
        return;
      }
    }

    await ref.read(
      liveRoomControllerProvider(widget.roomId, widget.isHost).future,
    );

    if (!widget.isHost) {
      unawaited(_sendJoinMessage());
    }
  }

  Future<void> _startInitialMedia() async {
    if (_initialMediaStarted || !widget.isHost) return;
    _initialMediaStarted = true;

    final controller = ref.read(
      liveRoomControllerProvider(widget.roomId, widget.isHost).notifier,
    );
    try {
      if (widget.source == LiveSource.screen) {
        await controller.toggleMic();
        if (mounted) {
          await controller.toggleScreenShare(
            context,
            sourceId: widget.screenSourceId,
          );
        }
      } else {
        await controller.toggleCamera();
        await controller.toggleMic();
      }
    } catch (e) {
      _initialMediaStarted = false;
      Toast.showNotificationNow('启动直播画面失败：$e');
    }
  }

  Future<void> _endLive() async {
    try {
      await DioClient().post('/live/end', data: {'roomId': widget.roomId});
    } catch (_) {}
  }

  Future<void> _leaveRoom() async {
    if (DeviceUtil.isRealDesktop()) {
      await windowManager.close();
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _bindRoomDataListener(Room room) {
    if (identical(_listeningRoom, room)) {
      return;
    }

    _roomListener?.dispose();
    _listeningRoom = room;
    _roomListener = room.createListener()
      ..on<DataReceivedEvent>((event) {
        _handleDataEvent(event);
      });
  }

  void _handleDataEvent(DataReceivedEvent event) {
    try {
      final json = jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
      final payload = json['payload'] as Map<String, dynamic>? ?? json;

      switch (event.topic) {
        case _danmakuTopic:
          _addMessage(
            _LiveChatMessage(
              text: payload['text']?.toString() ?? '',
              isHost: payload['isHost'] == true,
              name: payload['name']?.toString() ?? '观众',
            ),
          );
          break;
        case _cohostRequestTopic:
          if (!widget.isHost) return;
          final identity = payload['identity']?.toString() ?? '';
          if (identity.isEmpty) return;
          setState(() {
            _cohostRequests[identity] = _CohostRequest(
              identity: identity,
              name: payload['name']?.toString() ?? identity,
            );
          });
          Toast.showNotificationNow(
            '${_cohostRequests[identity]?.name ?? identity} 申请连麦',
          );
          break;
        case _cohostResponseTopic:
          if (widget.isHost) return;
          final identity = payload['identity']?.toString();
          final localIdentity = _localIdentity;
          if (identity != localIdentity) return;
          final accepted = payload['accepted'] == true;
          setState(() {
            _cohostRequested = false;
            _cohostActive = accepted;
          });
          Toast.showNotificationNow(accepted ? '主播已同意连麦' : '主播拒绝了连麦申请');
          if (accepted) {
            unawaited(_enableAudienceMic());
          }
          break;
      }
    } catch (e) {
      Toast.showNotificationNow('处理直播互动消息失败：$e');
    }
  }

  String get _localIdentity {
    final state = ref.read(
      liveRoomControllerProvider(widget.roomId, widget.isHost),
    );
    return state.value?.room.localParticipant?.identity ?? '';
  }

  Future<void> _publishLiveEvent({
    required String topic,
    required Map<String, dynamic> payload,
  }) async {
    final current = ref.read(
      liveRoomControllerProvider(widget.roomId, widget.isHost),
    );
    final room = current.value?.room;
    final localParticipant = room?.localParticipant;
    if (localParticipant == null) return;

    await localParticipant.publishData(
      utf8.encode(
        jsonEncode({
          'payload': payload,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ),
      reliable: true,
      topic: topic,
    );
  }

  Future<void> _sendJoinMessage() async {
    if (_joinMessageSent) return;
    _joinMessageSent = true;

    final current = ref.read(
      liveRoomControllerProvider(widget.roomId, widget.isHost),
    );
    final participant = current.value?.room.localParticipant;
    final name = _participantName(participant);
    final text = '$name 进入直播间';

    if (!mounted) return;
    _addMessage(_LiveChatMessage(text: text, isHost: false, name: '系统'));

    try {
      await _publishLiveEvent(
        topic: _danmakuTopic,
        payload: {'text': text, 'isHost': false, 'name': '系统', 'system': true},
      );
    } catch (e) {
      _joinMessageSent = false;
      Toast.showNotificationNow('进入直播间提示发送失败：$e');
    }
  }

  String _participantName(Participant? participant) {
    if (participant == null) return '观众';
    try {
      final metadata =
          jsonDecode(participant.metadata ?? '{}') as Map<String, dynamic>;
      final nickName = metadata['nickName']?.toString();
      if (nickName != null && nickName.trim().isNotEmpty) {
        return nickName.trim();
      }
    } catch (_) {}
    return participant.identity;
  }

  void _addMessage(_LiveChatMessage message) {
    if (message.text.trim().isEmpty) return;
    setState(() {
      _messages.add(message);
    });
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final message = _LiveChatMessage(
      text: text,
      isHost: widget.isHost,
      name: widget.isHost ? '主播' : '我',
    );
    _addMessage(message);
    _chatController.clear();

    try {
      await _publishLiveEvent(
        topic: _danmakuTopic,
        payload: {
          'text': text,
          'isHost': widget.isHost,
          'name': widget.isHost ? '主播' : '观众',
        },
      );
    } catch (e) {
      Toast.showNotificationNow('弹幕发送失败：$e');
    }
  }

  Future<void> _requestCohost() async {
    if (_cohostRequested || _cohostActive) return;
    final identity = _localIdentity;
    if (identity.isEmpty) return;

    setState(() => _cohostRequested = true);
    try {
      await _publishLiveEvent(
        topic: _cohostRequestTopic,
        payload: {'identity': identity, 'name': '观众 $identity'},
      );
      Toast.showNotificationNow('已发送连麦申请');
    } catch (e) {
      setState(() => _cohostRequested = false);
      Toast.showNotificationNow('连麦申请发送失败：$e');
    }
  }

  Future<void> _respondCohost(_CohostRequest request, bool accepted) async {
    setState(() {
      _cohostRequests.remove(request.identity);
    });

    try {
      final res = await DioClient().post(
        '/live/cohost/respond',
        data: {
          'roomId': widget.roomId,
          'identity': request.identity,
          'accepted': accepted,
        },
      );
      if (res.data?['code'] != 200) {
        throw Exception(res.data?['msg'] ?? res.data?['message'] ?? '处理失败');
      }
      await _publishLiveEvent(
        topic: _cohostResponseTopic,
        payload: {'identity': request.identity, 'accepted': accepted},
      );
    } catch (e) {
      Toast.showNotificationNow('处理连麦申请失败：$e');
    }
  }

  Future<void> _enableAudienceMic() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      Toast.showNotificationNow('需要开启麦克风权限才能连麦');
      return;
    }
    await ref
        .read(liveRoomControllerProvider(widget.roomId, widget.isHost).notifier)
        .toggleMic();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      liveRoomControllerProvider(widget.roomId, widget.isHost),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.isHost ? '正在直播' : '直播间'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: DeviceUtil.isRealMobile(),
      ),
      body: state.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '进入直播失败: $err',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        data: (roomState) {
          _bindRoomDataListener(roomState.room);
          unawaited(_startInitialMedia());

          final participants = <Participant>[
            if (roomState.room.localParticipant != null)
              roomState.room.localParticipant!,
            ...roomState.remoteParticipants,
          ];

          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: participants.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.live_tv,
                            size: 72,
                            color: Colors.white70,
                          ),
                        )
                      : _LiveVideoSurface(
                          participant: participants.first,
                          label: widget.isHost ? '主播画面' : '当前画面',
                        ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _RoomHeader(
                  isHost: widget.isHost,
                  roomId: widget.roomId,
                  title: widget.title,
                  visibility: widget.visibility,
                  source: widget.source,
                  connectionState: roomState.connectionState.name,
                  participantCount: participants.length,
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    if (widget.isHost && _cohostRequests.isNotEmpty) ...[
                      _CohostRequestBar(
                        requests: _cohostRequests.values.toList(),
                        onAccept: (request) => _respondCohost(request, true),
                        onReject: (request) => _respondCohost(request, false),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (!widget.isHost) ...[
                      _ChatPanel(messages: _messages),
                      const SizedBox(height: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          if (!widget.isHost) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _chatController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: '说点什么...',
                                      hintStyle: TextStyle(
                                        color: Colors.white54,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _sendMessage,
                                  icon: const Icon(
                                    Icons.send,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                          ],
                          _LiveControls(
                            isHost: widget.isHost,
                            cohostRequested: _cohostRequested,
                            cohostActive: _cohostActive,
                            onRequestCohost: _requestCohost,
                            onToggleCamera: () => ref
                                .read(
                                  liveRoomControllerProvider(
                                    widget.roomId,
                                    widget.isHost,
                                  ).notifier,
                                )
                                .toggleCamera(),
                            onToggleMic: () => ref
                                .read(
                                  liveRoomControllerProvider(
                                    widget.roomId,
                                    widget.isHost,
                                  ).notifier,
                                )
                                .toggleMic(),
                            onShareScreen: () => ref
                                .read(
                                  liveRoomControllerProvider(
                                    widget.roomId,
                                    widget.isHost,
                                  ).notifier,
                                )
                                .toggleScreenShare(context),
                            onLeave: _leaveRoom,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  final bool isHost;
  final String roomId;
  final String title;
  final LiveVisibility visibility;
  final LiveSource source;
  final String connectionState;
  final int participantCount;

  const _RoomHeader({
    required this.isHost,
    required this.roomId,
    required this.title,
    required this.visibility,
    required this.source,
    required this.connectionState,
    required this.participantCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(
                label: isHost ? '主播' : '观众',
                color: isHost ? Colors.redAccent : Colors.blueAccent,
              ),
              const SizedBox(width: 8),
              _Badge(
                label: visibility.label,
                color: visibility == LiveVisibility.public
                    ? Colors.green
                    : Colors.deepPurpleAccent,
              ),
              const SizedBox(width: 8),
              _Badge(label: source.label, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.isEmpty
                      ? (isHost ? '你正在直播 $roomId' : '你正在观看 $roomId')
                      : title,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '房间号: $roomId · 状态: $connectionState · 参与者: $participantCount',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _ChatPanel extends StatelessWidget {
  final List<_LiveChatMessage> messages;

  const _ChatPanel({required this.messages});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '弹幕互动',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${message.name}: ',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: message.isHost
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveControls extends StatelessWidget {
  final bool isHost;
  final bool cohostRequested;
  final bool cohostActive;
  final VoidCallback onRequestCohost;
  final VoidCallback onToggleCamera;
  final VoidCallback onToggleMic;
  final VoidCallback onShareScreen;
  final VoidCallback onLeave;

  const _LiveControls({
    required this.isHost,
    required this.cohostRequested,
    required this.cohostActive,
    required this.onRequestCohost,
    required this.onToggleCamera,
    required this.onToggleMic,
    required this.onShareScreen,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (isHost || cohostActive)
          FilledButton.icon(
            onPressed: onToggleCamera,
            icon: const Icon(Icons.videocam),
            label: const Text('摄像头'),
          ),
        if (isHost || cohostActive)
          FilledButton.icon(
            onPressed: onToggleMic,
            icon: const Icon(Icons.mic),
            label: const Text('麦克风'),
          ),
        if (isHost)
          FilledButton.icon(
            onPressed: onShareScreen,
            icon: const Icon(Icons.screen_share),
            label: const Text('共享屏幕'),
          ),
        if (!isHost)
          FilledButton.tonalIcon(
            onPressed: cohostRequested || cohostActive ? null : onRequestCohost,
            icon: Icon(cohostActive ? Icons.record_voice_over : Icons.call),
            label: Text(
              cohostActive ? '连麦中' : (cohostRequested ? '申请中' : '申请连麦'),
            ),
          ),
        FilledButton.icon(
          onPressed: onLeave,
          icon: const Icon(Icons.exit_to_app),
          label: Text(isHost ? '结束直播' : '离开'),
        ),
      ],
    );
  }
}

class _CohostRequestBar extends StatelessWidget {
  final List<_CohostRequest> requests;
  final ValueChanged<_CohostRequest> onAccept;
  final ValueChanged<_CohostRequest> onReject;

  const _CohostRequestBar({
    required this.requests,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final request = requests.first;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.record_voice_over, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${request.name} 申请连麦',
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => onReject(request),
            child: const Text('拒绝'),
          ),
          FilledButton(
            onPressed: () => onAccept(request),
            child: const Text('同意'),
          ),
        ],
      ),
    );
  }
}

class _LiveVideoSurface extends StatelessWidget {
  final Participant participant;
  final String label;

  const _LiveVideoSurface({required this.participant, required this.label});

  VideoTrack? _visibleVideoTrack() {
    for (final publication in participant.videoTrackPublications) {
      if (publication.isScreenShare &&
          !publication.muted &&
          publication.subscribed &&
          publication.track is VideoTrack) {
        return publication.track as VideoTrack;
      }
    }
    for (final publication in participant.videoTrackPublications) {
      if (!publication.isScreenShare &&
          !publication.muted &&
          publication.subscribed &&
          publication.track is VideoTrack) {
        return publication.track as VideoTrack;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final track = _visibleVideoTrack();
    return Stack(
      children: [
        if (track != null)
          VideoTrackRenderer(track, fit: VideoViewFit.contain)
        else
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off, size: 72, color: Colors.white54),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              participant.identity,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveChatMessage {
  final String name;
  final String text;
  final bool isHost;

  const _LiveChatMessage({
    required this.name,
    required this.text,
    required this.isHost,
  });
}

class _CohostRequest {
  final String identity;
  final String name;

  const _CohostRequest({required this.identity, required this.name});
}

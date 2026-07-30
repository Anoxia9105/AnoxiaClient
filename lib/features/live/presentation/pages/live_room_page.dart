import 'dart:async';
import 'dart:convert';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/utils/app_permission.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/framework/provider/live/live_room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';

part 'live_room_widgets.dart';
part 'live_room_models.dart';

enum LiveVisibility {
  public,
  private;
}

extension LiveVisibilityX on LiveVisibility {
  String get label => this == LiveVisibility.public ? '公开' : '私密';
  String trLabel() => this == LiveVisibility.public ? 'live_visibility_public'.tr() : 'live_visibility_private'.tr();
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
}

extension LiveSourceX on LiveSource {
  String get label => this == LiveSource.camera ? '摄像头' : '屏幕共享';
  String trLabel() => this == LiveSource.camera ? 'live_source_camera'.tr() : 'live_source_screen'.tr();
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
  static const int _maxMessageCount = 200;
  static const int _messageCharLimit = 300;
  static const Duration _cohostRequestTimeout = Duration(seconds: 20);

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
  bool _handledAudienceDisconnected = false;
  String _lastSentText = '';
  DateTime? _lastSentAt;
  Timer? _cohostRequestTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enterRoom();
    });
  }

  @override
  void dispose() {
    _cohostRequestTimer?.cancel();
    _roomListener?.dispose();
    _chatController.dispose();
    if (widget.isHost) {
      unawaited(_endLive());
    }
    super.dispose();
  }

  Future<void> _enterRoom() async {
    if (widget.isHost) {
      final mic = await ensureAppPermission(
        context,
        Permission.microphone,
        permissionName: '麦克风',
      );
      if (!mounted) return;
      final camera = widget.source == LiveSource.camera
          ? await ensureAppPermission(
              context,
              Permission.camera,
              permissionName: '摄像头',
            )
          : null;
      if (!mic || camera == false) {
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
      Toast.showNotificationNow('live_start_video_error'.tr(args: [e.toString()]));
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
          final action = payload['action']?.toString() ?? 'request';

          if (action == 'cancel') {
            final removed = _cohostRequests.remove(identity);
            if (removed != null && mounted) {
              setState(() {});
              Toast.showNotificationNow('live_cohost_request_cancelled'.tr(args: [removed.name]));
            }
            return;
          }

          final existed = _cohostRequests.containsKey(identity);
          setState(() {
            _cohostRequests[identity] = _CohostRequest(
              identity: identity,
              name: payload['name']?.toString() ?? identity,
            );
          });
          if (!existed) {
            Toast.showNotificationNow(
              '${_cohostRequests[identity]?.name ?? identity} 申请连麦',
            );
          }
          break;
        case _cohostResponseTopic:
          if (widget.isHost) return;
          final identity = payload['identity']?.toString();
          final localIdentity = _localIdentity;
          if (identity != localIdentity) return;
          final accepted = payload['accepted'] == true;
          final reason = payload['reason']?.toString();
          _clearCohostRequestState();
          setState(() {
            _cohostActive = accepted;
          });
          if (accepted) {
            Toast.showNotificationNow('live_cohost_request_accepted'.tr());
          } else {
            Toast.showNotificationNow(reason?.isNotEmpty == true ? reason! : 'live_cohost_request_rejected'.tr());
          }
          if (accepted) {
            unawaited(_enableAudienceMic());
          }
          break;
      }
    } catch (e) {
      Toast.showNotificationNow('live_interact_message_error'.tr(args: [e.toString()]));
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
      Toast.showNotificationNow('live_enter_notify_error'.tr(args: [e.toString()]));
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
    final trimmed = message.text.trim();
    if (trimmed.isEmpty) return;
    final normalized = trimmed.length > _messageCharLimit
        ? '${trimmed.substring(0, _messageCharLimit)}...'
        : trimmed;

    setState(() {
      _messages.add(message.copyWith(text: normalized));
      if (_messages.length > _maxMessageCount) {
        _messages.removeRange(0, _messages.length - _maxMessageCount);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    if (_lastSentText == text &&
        _lastSentAt != null &&
        now.difference(_lastSentAt!) < const Duration(seconds: 2)) {
      Toast.showNotificationNow('live_send_too_fast'.tr());
      return;
    }
    _lastSentText = text;
    _lastSentAt = now;

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
      Toast.showNotificationNow('live_danmaku_send_error'.tr(args: [e.toString()]));
    }
  }

  Future<void> _requestCohost() async {
    if (_cohostRequested || _cohostActive) return;
    final identity = _localIdentity;
    if (identity.isEmpty) return;

    final current = ref.read(
      liveRoomControllerProvider(widget.roomId, widget.isHost),
    );
    if (current.value?.connectionState.name != 'connected') {
      Toast.showNotificationNow('live_not_ready_retry'.tr());
      return;
    }

    setState(() => _cohostRequested = true);
    _startCohostRequestTimer();
    try {
      final participant = current.value?.room.localParticipant;
      final name = _participantName(participant);
      await _publishLiveEvent(
        topic: _cohostRequestTopic,
        payload: {'identity': identity, 'name': name, 'action': 'request'},
      );
      Toast.showNotificationNow('live_cohost_request_sent'.tr());
    } catch (e) {
      _clearCohostRequestState();
      Toast.showNotificationNow('live_cohost_request_error'.tr(args: [e.toString()]));
    }
  }

  Future<void> _cancelCohostRequest() async {
    if (!_cohostRequested || _cohostActive) return;
    final identity = _localIdentity;
    if (identity.isEmpty) {
      _clearCohostRequestState();
      return;
    }

    _clearCohostRequestState();
    try {
      await _publishLiveEvent(
        topic: _cohostRequestTopic,
        payload: {'identity': identity, 'action': 'cancel'},
      );
      Toast.showNotificationNow('live_cohost_request_cancelled_success'.tr());
    } catch (e) {
      Toast.showNotificationNow('live_cohost_request_cancel_error'.tr(args: [e.toString()]));
    }
  }

  void _startCohostRequestTimer() {
    _cohostRequestTimer?.cancel();
    _cohostRequestTimer = Timer(_cohostRequestTimeout, () {
      if (!mounted || !_cohostRequested || _cohostActive) return;
      _clearCohostRequestState();
      Toast.showNotificationNow('live_cohost_request_timeout'.tr());
    });
  }

  void _clearCohostRequestState() {
    _cohostRequestTimer?.cancel();
    _cohostRequestTimer = null;
    if (mounted && _cohostRequested) {
      setState(() => _cohostRequested = false);
    } else {
      _cohostRequested = false;
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
        payload: {
          'identity': request.identity,
          'accepted': accepted,
          'reason': accepted ? '主播已同意连麦' : '主播拒绝了连麦申请',
        },
      );
    } catch (e) {
      Toast.showNotificationNow('live_cohost_request_process_error'.tr(args: [e.toString()]));
    }
  }

  Future<void> _enableAudienceMic() async {
    final mic = await ensureAppPermission(
      context,
      Permission.microphone,
      permissionName: '麦克风',
    );
    if (!mic) {
      Toast.showNotificationNow('live_mic_permission_required_for_cohost'.tr());
      return;
    }
    await ref
        .read(liveRoomControllerProvider(widget.roomId, widget.isHost).notifier)
        .toggleMic();
  }

  Future<void> _toggleCamera() {
    return ref
        .read(liveRoomControllerProvider(widget.roomId, widget.isHost).notifier)
        .toggleCamera();
  }

  Future<void> _toggleMic() {
    return ref
        .read(liveRoomControllerProvider(widget.roomId, widget.isHost).notifier)
        .toggleMic();
  }

  Future<void> _shareScreen() {
    return ref
        .read(liveRoomControllerProvider(widget.roomId, widget.isHost).notifier)
        .toggleScreenShare(context);
  }

  void _syncAudienceDisconnectedState(RoomState roomState) {
    final disconnected = roomState.connectionState.name == 'disconnected';
    if (widget.isHost || !disconnected) {
      _handledAudienceDisconnected = false;
      return;
    }
    if (_handledAudienceDisconnected) return;

    _handledAudienceDisconnected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Toast.showNotificationNow('live_ended_or_disconnected'.tr());
      unawaited(_leaveRoom());
    });
  }

  AppBar _buildAppBar(bool isDesktop) {
    return AppBar(
      title: Text(widget.isHost ? '正在直播' : '直播间'),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      centerTitle: DeviceUtil.isRealMobile(),
      leading: isDesktop
          ? null
          : IconButton(
              onPressed: _leaveRoom,
              icon: const Icon(Icons.arrow_back),
            ),
      automaticallyImplyLeading: !isDesktop,
      flexibleSpace: isDesktop
          ? const DragToMoveArea(child: SizedBox.expand())
          : null,
      actions: [
        if (isDesktop) ...[
          IconButton(
            tooltip: 'call_minimize_tooltip'.tr(),
            onPressed: () => windowManager.minimize(),
            icon: const Icon(Icons.minimize),
          ),
          IconButton(
            tooltip: 'call_close_tooltip'.tr(),
            onPressed: _leaveRoom,
            icon: const Icon(Icons.close),
          ),
        ],
      ],
    );
  }

  Widget _buildStateBody(AsyncValue<RoomState> state) {
    return state.when(
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
      data: _buildConnectedBody,
    );
  }

  Widget _buildConnectedBody(RoomState roomState) {
    _bindRoomDataListener(roomState.room);
    unawaited(_startInitialMedia());
    _syncAudienceDisconnectedState(roomState);

    final showDesktopSidePanel = DeviceUtil.isRealDesktop();
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
          right: showDesktopSidePanel ? 364 : 12,
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
        if (showDesktopSidePanel)
          Positioned(
            top: 88,
            right: 12,
            bottom: 12,
            width: 340,
            child: _LiveSidePanel(
              messages: _messages,
              chatController: _chatController,
              isHost: widget.isHost,
              onSend: _sendMessage,
            ),
          ),
        Positioned(
          bottom: 12,
          left: 12,
          right: showDesktopSidePanel ? 364 : 12,
          child: _BottomControlSection(
            isHost: widget.isHost,
            cohostRequests: _cohostRequests.values.toList(),
            cohostRequested: _cohostRequested,
            cohostActive: _cohostActive,
            showMobileChat: !widget.isHost && !showDesktopSidePanel,
            messages: _messages,
            chatController: _chatController,
            onSendMessage: _sendMessage,
            onAcceptCohost: (request) => _respondCohost(request, true),
            onRejectCohost: (request) => _respondCohost(request, false),
            onRequestCohost: _requestCohost,
            onCancelCohostRequest: _cancelCohostRequest,
            onToggleCamera: _toggleCamera,
            onToggleMic: _toggleMic,
            onShareScreen: _shareScreen,
            onLeave: _leaveRoom,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      liveRoomControllerProvider(widget.roomId, widget.isHost),
    );
    final isDesktop = DeviceUtil.isRealDesktop();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(isDesktop),
      body: _buildStateBody(state),
    );
  }
}

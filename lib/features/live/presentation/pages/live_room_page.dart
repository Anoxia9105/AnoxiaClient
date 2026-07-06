import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/provider/live/live_room_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveRoomPage extends ConsumerStatefulWidget {
  final String roomId;
  final bool isHost;

  const LiveRoomPage({super.key, required this.roomId, required this.isHost});

  @override
  ConsumerState<LiveRoomPage> createState() => _LiveRoomPageState();
}

class _LiveRoomPageState extends ConsumerState<LiveRoomPage> {
  final TextEditingController _chatController = TextEditingController();
  final List<_LiveChatMessage> _messages = [
    _LiveChatMessage(text: '欢迎进入直播间，开始互动吧', isHost: true, name: '系统'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enterRoom();
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _enterRoom() async {
    if (widget.isHost) {
      final camera = await Permission.camera.request();
      final mic = await Permission.microphone.request();
      if (!camera.isGranted || !mic.isGranted) {
        if (!mounted) return;
        Toast.showNotificationNow('需要开启摄像头和麦克风权限');
        if (mounted) Navigator.of(context).pop();
        return;
      }
    }

    await ref.read(
      liveRoomControllerProvider(widget.roomId, widget.isHost).future,
    );
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        _LiveChatMessage(
          text: text,
          isHost: widget.isHost,
          name: widget.isHost ? '主播' : '我',
        ),
      );
      _chatController.clear();
    });
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
                child: Container(
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isHost
                                  ? Colors.redAccent
                                  : Colors.blueAccent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              widget.isHost ? '主播' : '观众',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.isHost
                                  ? '你正在直播 ${widget.roomId}'
                                  : '你正在观看 ${widget.roomId}',
                              style: const TextStyle(color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '状态: ${roomState.connectionState.name} · 参与者 ${participants.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    Container(
                      height: 180,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '聊天互动',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _chatController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: '说点什么...',
                                    hintStyle: TextStyle(color: Colors.white54),
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
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (widget.isHost)
                                FilledButton.icon(
                                  onPressed: () => ref
                                      .read(
                                        liveRoomControllerProvider(
                                          widget.roomId,
                                          widget.isHost,
                                        ).notifier,
                                      )
                                      .toggleCamera(),
                                  icon: const Icon(Icons.videocam),
                                  label: const Text('摄像头'),
                                ),
                              if (widget.isHost)
                                FilledButton.icon(
                                  onPressed: () => ref
                                      .read(
                                        liveRoomControllerProvider(
                                          widget.roomId,
                                          widget.isHost,
                                        ).notifier,
                                      )
                                      .toggleMic(),
                                  icon: const Icon(Icons.mic),
                                  label: const Text('麦克风'),
                                ),
                              if (widget.isHost)
                                FilledButton.icon(
                                  onPressed: () => ref
                                      .read(
                                        liveRoomControllerProvider(
                                          widget.roomId,
                                          widget.isHost,
                                        ).notifier,
                                      )
                                      .toggleScreenShare(context),
                                  icon: const Icon(Icons.screen_share),
                                  label: const Text('共享屏幕'),
                                ),
                              FilledButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.exit_to_app),
                                label: const Text('离开'),
                              ),
                            ],
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

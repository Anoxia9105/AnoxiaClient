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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enterRoom();
    });
  }

  Future<void> _enterRoom() async {
    if (widget.isHost) {
      final camera = await Permission.camera.request();
      final mic = await Permission.microphone.request();
      if (!camera.isGranted || !mic.isGranted) {
        if (!mounted) return;
        Toast.showNotificationNow('需要开启摄像头和麦克风权限');
        Navigator.of(context).pop();
        return;
      }
    }

    await ref.read(
      liveRoomControllerProvider(widget.roomId, widget.isHost).future,
    );
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
        loading: () => const Center(child: CircularProgressIndicator()),
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
              if (participants.isNotEmpty)
                Positioned.fill(
                  child: participants.first.videoTrackPublications.isNotEmpty
                      ? const Center(
                          child: Icon(
                            Icons.videocam,
                            size: 72,
                            color: Colors.white70,
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.person,
                            size: 72,
                            color: Colors.white70,
                          ),
                        ),
                )
              else
                const Center(
                  child: Icon(Icons.live_tv, size: 72, color: Colors.white70),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.isHost
                              ? '你正在直播 ${widget.roomId}'
                              : '你正在观看 ${widget.roomId}',
                          style: const TextStyle(color: Colors.white),
                        ),
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
                              .toggleCamera(),
                          icon: const Icon(Icons.videocam),
                          label: const Text('摄像头'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

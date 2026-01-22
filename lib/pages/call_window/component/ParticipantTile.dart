// participant_tile.dart

import 'dart:convert';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:hugeicons/hugeicons.dart';

class ParticipantTile extends StatefulWidget {
  final Participant participant;

  const ParticipantTile({super.key, required this.participant});

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  // 当前应该显示的视频轨道
  VideoTrack? videoTrack;

  // 监听器函数句柄
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      // 可以在这里做节流，但通常 setState 开销在单个组件内很小
      if (mounted) setState(() {});
    };

    widget.participant.addListener(_listener);
  }

  @override
  void dispose() {
    // 2. 移除监听，防止内存泄漏
    widget.participant.removeListener(_listener);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ParticipantTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.participant != widget.participant) {
      oldWidget.participant.removeListener(_listener);
      widget.participant.addListener(_listener);
    }
  }

  /// 计算当前应该显示哪个视频轨道 (屏幕共享 > 摄像头)
  VideoTrack? _getVisibleVideoTrack() {
    // 优先找屏幕共享
    final screenPub = widget.participant.videoTrackPublications
        .where((pub) => pub.isScreenShare && !pub.muted && pub.subscribed)
        .firstOrNull;

    if (screenPub?.track != null && screenPub?.track is VideoTrack) {
      return screenPub!.track as VideoTrack;
    }
    // 2. 其次找摄像头
    final cameraPub = widget.participant.videoTrackPublications
        .where((pub) => !pub.isScreenShare && !pub.muted && pub.subscribed)
        .firstOrNull;

    if (cameraPub?.track != null && cameraPub?.track is VideoTrack) {
      return cameraPub!.track as VideoTrack;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.participant;
    final track = _getVisibleVideoTrack();

    // 解析元数据 (头像/昵称)
    Map<String, dynamic> meta = {};
    try {
      if (p.metadata != null && p.metadata!.isNotEmpty) {
        meta = jsonDecode(p.metadata!);
      }
    } catch (_) {}

    final nickName = meta['nickName'] ?? p.identity ?? 'Unknown';
    final avatarUrl = meta['avatar'] ?? '';
    final isSpeaking = p.isSpeaking;
    final isMuted = p.isMicrophoneEnabled() == false;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSpeaking
                ? Colors.blueAccent
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
            width: isSpeaking ? 2.0 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (track != null)
                VideoTrackRenderer(track, fit: VideoViewFit.contain)
              else
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 使用你的 AvatarWidget
                      AvatarWidget(size: 60.w, url: avatarUrl, name: nickName),
                    ],
                  ),
                ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMuted)
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedMicOff01,
                          size: 16,
                          color: Colors.white,
                        )
                      else
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedMic01,
                          size: 16,
                          color: Colors.white,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        nickName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

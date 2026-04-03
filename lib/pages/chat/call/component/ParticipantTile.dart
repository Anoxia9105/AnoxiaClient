// participant_tile.dart

import 'dart:convert';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/pages/chat/call/component/VolumeIndicator.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';

// local helper to convert quality/rtt to icon
Widget _buildSignalIconForParticipant(Participant p) {
  final quality = p.connectionQuality;

  Color color;
  int level;
  String qualityLabel;

  switch (quality) {
    case ConnectionQuality.lost:
      color = Colors.redAccent;
      level = 1;
      qualityLabel = 'call_quality_lost'.tr();
      break;
    case ConnectionQuality.poor:
      color = Colors.orange;
      level = 2;
      qualityLabel = 'call_quality_poor'.tr();
      break;
    case ConnectionQuality.good:
    case ConnectionQuality.excellent:
      color = Colors.green;
      level = 3;
      qualityLabel = quality == ConnectionQuality.excellent
          ? 'call_quality_excellent'.tr()
          : 'call_quality_good'.tr();
      break;
    default:
      color = Colors.grey;
      level = 0;
      qualityLabel = 'call_quality_unknown'.tr();
  }

  Widget bar(int idx) {
    final active = level >= idx;
    final double h = 4.0 + idx * 3.0;
    return Container(
      width: 2.5,
      height: h,
      margin: const EdgeInsets.symmetric(horizontal: 1.0),
      decoration: BoxDecoration(
        color: active ? color : Colors.white10,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  return Tooltip(
    message: qualityLabel,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [bar(1), bar(2), bar(3)],
      ),
    ),
  );
}

class ParticipantTile extends StatefulWidget {
  final Participant participant;
  final bool handRaised;

  const ParticipantTile({
    super.key,
    required this.participant,
    this.handRaised = false,
  });

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  // 当前应该显示的视频轨道
  VideoTrack? videoTrack;

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
    final isCurrentUser = p is LocalParticipant;
    final isMuted = p.isMicrophoneEnabled() == false;
    final volume = p.audioLevel;

    // 检查是否屏幕共享
    // final isScreenShare = p.videoTrackPublications.any(
    //   (pub) => pub.isScreenShare && !pub.muted && pub.subscribed,
    // );

    // 屏幕共享时显示特殊标签
    // final displayName = isScreenShare ? "$nickName's Screen" : nickName;
    final displayName = nickName;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
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
                      AvatarWidget(size: 48, url: avatarUrl, name: nickName),
                    ],
                  ),
                ),
              if (widget.handRaised)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('✋', style: TextStyle(fontSize: 20)),
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
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      _buildSignalIconForParticipant(p),
                      if (!isCurrentUser)
                        IconButton(
                          constraints: const BoxConstraints(), // 移除最小尺寸限制
                          padding: EdgeInsets.all(1), // 移除默认内边距
                          tooltip: "更多",
                          onPressed: () {},
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedMoreHorizontal,
                            size: 14, // 你的图标尺寸
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // 音量指示器
              Positioned(
                left: 8,
                bottom: 36,
                child: VolumeIndicator(volume: volume),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

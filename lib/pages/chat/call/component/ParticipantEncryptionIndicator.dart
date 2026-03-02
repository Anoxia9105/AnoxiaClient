import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:easy_localization/easy_localization.dart';

/// 参与者 E2E 加密指示器
/// 显示参与者的音视频是否使用 E2E 加密
class ParticipantEncryptionIndicator extends StatelessWidget {
  final Participant participant;

  const ParticipantEncryptionIndicator({
    super.key,
    required this.participant,
  });

  bool _isEncrypted() {
    // 检查是否有加密的音频轨道
    final hasEncryptedAudio = participant.audioTrackPublications.any(
      (pub) => !pub.muted && pub.subscribed,
    );

    // 检查是否有加密的视频轨道
    final hasEncryptedVideo = participant.videoTrackPublications.any(
      (pub) => !pub.muted && pub.subscribed,
    );

    return hasEncryptedAudio || hasEncryptedVideo;
  }

  @override
  Widget build(BuildContext context) {
    final isEncrypted = _isEncrypted();

    if (!isEncrypted) {
      return SizedBox.shrink();
    }

    return Tooltip(
      message: 'call_encryption_indicator_tooltip'.tr(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.lock,
          size: 14,
          color: Colors.green,
        ),
      ),
    );
  }
}

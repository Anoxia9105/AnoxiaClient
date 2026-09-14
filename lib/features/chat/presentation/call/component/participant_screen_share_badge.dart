import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 屏幕共享标签，显示在共享视频区域顶部，标识「某用户正在共享屏幕」。
class ParticipantScreenShareBadge extends StatelessWidget {
  const ParticipantScreenShareBadge({
    super.key,
    required this.name,
    this.compact = false,
  });

  /// 正在共享屏幕的参与者昵称
  final String name;

  /// 是否使用紧凑模式（小窗/缩略图）
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(RadiusToken.sm),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedComputerScreenShare,
            size: compact ? 11 : 13,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            'call_participant_sharing'.tr(args: [name]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:anoxia/common/widgets/breathing_dot.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 在线人数胶囊徽章
///
/// 浅绿底 + 在线绿点 + 「N 在线」文字，用于群聊副标题、成员摘要、联系人分区头等
/// 需要与静态总数区分层级的场景：在线数是活的状态（强调），总数是静态属性（弱化）。
class OnlineStatusPill extends StatelessWidget {
  /// 胶囊内文字，如「12 在线」（调用方负责 i18n 组装）
  final String text;

  const OnlineStatusPill({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final success =
        Theme.of(context).extension<AppColors>()?.success ??
        colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BreathingDot(),
          const SizedBox(width: 5),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: success,
            ),
          ),
        ],
      ),
    );
  }
}

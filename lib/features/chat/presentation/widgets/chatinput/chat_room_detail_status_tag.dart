import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 聊天房间详情页状态提示标签组件
///
/// 用于显示房间的特殊状态提示，如：
/// - 全员禁言提示
/// - 房间已解散提示
class ChatRoomDetailStatusTag extends StatelessWidget {
  /// 提示文本内容
  final String text;

  /// 图标，支持 HugeIcons 的图标类型
  final dynamic icon;

  const ChatRoomDetailStatusTag({super.key, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 1,
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: icon ?? HugeIcons.strokeRoundedAlert02,
            size: 16,
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

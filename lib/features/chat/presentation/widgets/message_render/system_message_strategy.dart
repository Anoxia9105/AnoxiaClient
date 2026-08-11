// 系统消息渲染策略
//
// 实现系统消息的渲染逻辑，将系统消息以居中的标签形式展示在聊天界面中，
// 包含图标、文本和时间戳。
import 'package:anoxia/common/utils/date_util.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/features/chat/application/system_message_formatter.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:flutter/material.dart';

import 'base/message_render_strategy.dart';

/// 系统消息渲染策略
///
/// 将系统消息（如入群通知、退群通知等）渲染为居中的圆角标签，
/// 配合图标和格式化文本展示。使用 [SystemMessageFormatter] 解析消息内容。
class SystemMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final display = SystemMessageFormatter.display(message);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        child: _buildChip(
          context,
          icon: display.icon,
          text: display.text,
          timestamp: message.timestamp,
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required dynamic icon,
    required String text,
    required int? timestamp,
  }) {
    final cs = Theme.of(context).colorScheme;
    final fgColor = cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 14, color: fgColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: fgColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            DateUtil.formatTimestampToTime(timestamp),
            style: TextStyle(
              fontSize: 10,
              color: fgColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

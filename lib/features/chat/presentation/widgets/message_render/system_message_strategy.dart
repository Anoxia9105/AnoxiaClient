// 系统消息渲染策略
//
// 实现系统消息的渲染逻辑，将系统消息以居中的纯文本形式展示在聊天界面中，
// 仅包含图标和文字（无背景、无时间，时间由消息列表的时间分隔条承担）。
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/features/chat/application/system_message_formatter.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:flutter/material.dart';

import 'base/message_render_strategy.dart';

/// 系统消息渲染策略
///
/// 将系统消息（如入群通知、退群通知等）渲染为居中的图标 + 文本。
/// 使用 [SystemMessageFormatter] 解析消息内容。
class SystemMessageStrategy extends MessageRenderStrategy {
  /// 当前会话是否为群聊
  ///
  /// 仅影响「通话开始」文案：1:1 显示「xx 发起了通话」，
  /// 群聊（会议）才显示「xx 开启了会议」。
  final bool isGroup;

  SystemMessageStrategy({this.isGroup = false});

  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final display = SystemMessageFormatter.display(message, isGroup: isGroup);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        child: _buildChip(
          context,
          icon: display.icon,
          text: display.text,
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required dynamic icon,
    required String text,
  }) {
    final cs = Theme.of(context).colorScheme;
    final fgColor = cs.onSurfaceVariant;

    return Row(
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
      ],
    );
  }
}

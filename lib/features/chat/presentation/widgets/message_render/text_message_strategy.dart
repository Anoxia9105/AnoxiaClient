import 'package:flutter/material.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import 'base/message_render_strategy.dart';

/// 文本消息渲染策略
///
/// 处理普通文本消息和大表情消息的渲染
class TextMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final content = message.payload?.content ?? '';

    // 大表情渲染逻辑：当消息包含 emojiCode 且有内容时，以大字体显示
    if (message.payload?.emojiCode != null && content.isNotEmpty) {
      return Text(content, style: const TextStyle(fontSize: 48));
    }

    // 普通文本渲染：支持文本选择
    return SelectionArea(
      contextMenuBuilder: (context, selectableRegionState) {
        return const SizedBox.shrink();
      },
      child: Text(
        content,
        style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
      ),
    );
  }
}

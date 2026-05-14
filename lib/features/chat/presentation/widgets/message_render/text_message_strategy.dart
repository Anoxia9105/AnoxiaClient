import 'package:flutter/material.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import 'base/message_render_strategy.dart';

class TextMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final content = message.payload?.content ?? '';

    // 大表情渲染逻辑
    if (message.payload?.emojiCode != null && content.isNotEmpty) {
      return Text(content, style: const TextStyle(fontSize: 48));
    }

    // 普通文本渲染
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

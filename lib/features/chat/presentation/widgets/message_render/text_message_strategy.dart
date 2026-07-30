import 'package:flutter/material.dart';

import '../../../../../framework/domain/chat_message.dart';
import 'base/message_render_strategy.dart';
import 'link_preview_card.dart';

class TextMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final content = message.payload?.content ?? message.content;

    if (message.payload?.emojiCode?.isNotEmpty == true && content.isNotEmpty) {
      return Text(content, style: const TextStyle(fontSize: 48));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content,
          style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
        ),
        MessageLinkPreview(text: content),
      ],
    );
  }
}

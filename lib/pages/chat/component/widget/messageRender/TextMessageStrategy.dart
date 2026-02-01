import 'package:flutter/material.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import 'MessageRenderStrategy.dart';

class TextMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    if (message.payload?.emojiCode != null &&
        message.payload?.content != null) {
      return Text(message.payload?.content ?? '',style: TextStyle(fontSize: 48));
    }
    return SelectionArea(
      child: SelectableText(
        message.payload?.content ?? '',
        style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
      ),
    );
  }
}

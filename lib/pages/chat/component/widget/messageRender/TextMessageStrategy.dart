import 'package:flutter/material.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import 'MessageRenderStrategy.dart';

class TextMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(BuildContext context, ChatMessage message,Color textColor) {
    return SelectionArea(
      child: Text(
        message.payload?.content ?? '',
        style: TextStyle(color: textColor,fontSize: 15, height: 1.4),
      ),
    );
  }
}
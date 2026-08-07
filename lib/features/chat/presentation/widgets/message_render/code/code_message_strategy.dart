import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:flutter/material.dart';

import '../base/message_render_strategy.dart';
import 'code_block_view.dart';

class CodeMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final code = message.payload?.code;
    if (code == null) {
      return Text(
        message.content,
        style: TextStyle(color: textColor),
      );
    }
    return CodeBlockView(code: code.code);
  }
}

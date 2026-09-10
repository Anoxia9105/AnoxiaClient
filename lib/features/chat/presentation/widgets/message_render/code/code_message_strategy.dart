import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:easy_localization/easy_localization.dart';
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
    if (code == null || code.code.trim().isEmpty) {
      // 旧数据可能只有占位 content（如 [code]），此时展示本地化文案。
      final fallback = message.content.trim();
      if (fallback.isNotEmpty && !_isPlaceholder(fallback)) {
        return Text(
          message.content,
          style: TextStyle(color: textColor),
        );
      }
      return Text(
        'reply_placeholder_code'.tr(),
        style: TextStyle(color: textColor),
      );
    }
    return CodeBlockView(code: code.code);
  }

  static bool _isPlaceholder(String text) {
    final lower = text.trim().toLowerCase();
    const markers = {
      '[code]',
      '[empty]',
      '[代码]',
      'plaintext',
      '[plaintext]',
    };
    if (markers.contains(lower)) return true;
    final trimmed = text.trim();
    if (trimmed.length >= 3 &&
        trimmed.length <= 20 &&
        RegExp(r'^\[[A-Za-z0-9_+#-]+\]$').hasMatch(trimmed)) {
      return true;
    }
    return false;
  }
}

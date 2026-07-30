/// 文本消息渲染策略
///
/// 实现文本和表情消息的渲染逻辑，支持普通文本消息和超大表情消息的渲染，
/// 以及链接预览功能。
import 'package:flutter/material.dart';

import '../../../../../framework/domain/chat_message.dart';
import 'base/message_render_strategy.dart';
import 'link_preview_card.dart';

/// 文本消息渲染策略
///
/// 处理文本和富文本消息的渲染。当消息包含表情代码时以大号字体显示，
/// 普通文本消息则附带链接预览卡片（[MessageLinkPreview]）。
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

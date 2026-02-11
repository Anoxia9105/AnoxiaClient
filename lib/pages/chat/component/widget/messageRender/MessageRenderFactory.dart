import 'package:anoxia/pages/chat/component/widget/messageRender/QuillMessageStrategy.dart';
import 'package:anoxia/pages/chat/component/widget/messageRender/SystemMessageStrategy.dart';
import 'package:flutter/material.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import '../../../../../framework/protocol/message/MessageEunm.dart';
import 'FileMessageStrategy.dart';
import 'ImageMessageStrategy.dart';
import 'MessageRenderStrategy.dart';
import 'TextMessageStrategy.dart';

class MessageRenderFactory {
  static final Map<MessageType, MessageRenderStrategy> _strategies = {
    MessageType.text: TextMessageStrategy(),
    MessageType.image: ImageMessageStrategy(),
    MessageType.file: FileMessageStrategy(),
    MessageType.quill: QuillMessageStrategy(),
    MessageType.system: SystemMessageStrategy(),
    // 'VOICE': VoiceMessageStrategy(),
  };

  static MessageRenderStrategy getStrategy(MessageType? type) {
    return _strategies[type] ?? _DefaultMessageStrategy();
  }
}

// 兜底策略，处理未知类型
class _DefaultMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    return Text(
      "[消息解析错误]",
      style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
    );
  }
}

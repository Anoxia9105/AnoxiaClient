import 'package:anoxia/features/chat/presentation/widgets/message_render/quill_message_strategy.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/system_message_strategy.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../framework/domain/ChatMessage.dart';
import '../../../../../../framework/protocol/message/MessageEunm.dart';
import '../file_message_strategy.dart';
import '../image_message_strategy.dart';
import 'message_render_strategy.dart';
import '../text_message_strategy.dart';

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
      'chat_message_parse_error'.tr(),
      style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
    );
  }
}

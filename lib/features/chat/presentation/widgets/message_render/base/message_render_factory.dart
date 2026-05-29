import 'package:anoxia/features/chat/presentation/widgets/message_render/audio_message_strategy.dart';
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

/// 消息渲染工厂类
///
/// 采用策略模式，根据消息类型返回对应的渲染策略
class MessageRenderFactory {
  /// 消息类型到渲染策略的映射表
  static final Map<MessageType, MessageRenderStrategy> _strategies = {
    MessageType.text: TextMessageStrategy(),
    MessageType.image: ImageMessageStrategy(),
    MessageType.file: FileMessageStrategy(),
    MessageType.quill: QuillMessageStrategy(),
    MessageType.system: SystemMessageStrategy(),
    MessageType.audio: AudioMessageStrategy(),
  };

  /// 根据消息类型获取对应的渲染策略
  ///
  /// [type] 消息类型
  /// 返回对应的渲染策略，未知类型返回默认策略
  static MessageRenderStrategy getStrategy(MessageType? type) {
    return _strategies[type] ?? _DefaultMessageStrategy();
  }
}

/// 默认消息渲染策略
///
/// 当遇到未知消息类型时使用，显示错误提示
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

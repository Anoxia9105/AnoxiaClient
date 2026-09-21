import 'package:anoxia/features/chat/presentation/widgets/message_render/audio_message_strategy.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/card_message_strategy.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/code/code_message_strategy.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/location_message_strategy.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/quill_message_strategy.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/sticker_message_strategy.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/system_message_strategy.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/video_message_strategy.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../framework/domain/chat_message.dart';
import '../../../../../../framework/protocol/message/message_enum.dart';
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
    MessageType.richText: QuillMessageStrategy(),
    MessageType.audio: AudioMessageStrategy(),
    MessageType.video: VideoMessageStrategy(),
    MessageType.emoji: StickerMessageStrategy(),
    MessageType.location: LocationMessageStrategy(),
    MessageType.card: CardMessageStrategy(),
    MessageType.codeSnippet: CodeMessageStrategy(),
  };

  /// 根据消息类型获取对应的渲染策略
  ///
  /// [type] 消息类型
  /// [isGroup] 当前会话是否为群聊（系统消息的通话文案需要区分单聊/群聊）。
  /// 返回对应的渲染策略，未知类型返回默认策略
  static MessageRenderStrategy getStrategy(
    MessageType? type, {
    bool isGroup = false,
  }) {
    // 系统消息需要携带会话类型：同为 CALL_STARTED，1:1 是「发起了通话」，
    // 群聊才是「开启了会议」，故不能复用无状态的单例。
    if (type == MessageType.system) {
      return SystemMessageStrategy(isGroup: isGroup);
    }
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
      style: TextStyle(color: Theme.of(context).colorScheme.error, fontStyle: FontStyle.italic),
    );
  }
}

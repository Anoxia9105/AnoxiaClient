// 消息预览文本格式化工具。
//
// 将聊天消息转换为本地化、用户可读的简短预览文本，
// 用于消息列表等紧凑展示场景。
import 'package:anoxia/features/chat/application/system_message_formatter.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:easy_localization/easy_localization.dart';

/// Produces localized, user-facing text for compact message previews.
abstract final class MessagePreviewFormatter {
  /// 格式化消息为预览文本。
  ///
  /// [message] 需要格式化的聊天消息，为 `null` 时返回 [fallback]。
  /// [fallback] 消息为空时的默认文本。
  static String format(ChatMessage? message, {String fallback = ''}) {
    if (message == null) return fallback;
    if (SystemMessageFormatter.isSystemMessage(message)) {
      return SystemMessageFormatter.previewText(message);
    }

    return switch (message.messageType) {
      MessageType.image => 'quill_image_plain'.tr(),
      MessageType.audio => 'quill_audio_plain'.tr(),
      MessageType.file => 'quill_file_plain'.tr(),
      _ => message.content,
    };
  }
}

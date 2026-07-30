import 'package:anoxia/features/chat/presentation/formatters/system_message_formatter.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:easy_localization/easy_localization.dart';

/// Produces localized, user-facing text for compact message previews.
abstract final class MessagePreviewFormatter {
  static String format(ChatMessage? message, {String fallback = ''}) {
    if (message == null) return fallback;
    if (SystemMessageFormatter.isSystemMessage(message)) {
      return SystemMessageFormatter.previewText(message);
    }

    return switch (message.messageType) {
      MessageType.image => 'quill_image_plain'.tr(),
      MessageType.file => 'quill_file_plain'.tr(),
      _ => message.content,
    };
  }
}

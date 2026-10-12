// 消息预览文本格式化工具。
//
// 将聊天消息转换为本地化、用户可读的简短预览文本，
// 用于会话列表、搜索结果与系统通知等紧凑展示场景。
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

    switch (message.messageType) {
      case MessageType.image:
        return _meaningfulContent(message) ?? 'quill_image_plain'.tr();
      case MessageType.audio:
        // 语音无文本内容，直接展示本地化占位。
        return 'quill_audio_plain'.tr();
      case MessageType.video:
        return _meaningfulContent(message) ?? 'reply_placeholder_video'.tr();
      case MessageType.file:
        final content = _meaningfulContent(message);
        if (content != null) return content;
        final name = message.payload?.file?.name?.trim();
        if (name != null && name.isNotEmpty) return name;
        return 'quill_file_plain'.tr();
      case MessageType.codeSnippet:
        final code = message.payload?.code;
        final title = code?.title?.trim();
        if (title != null && title.isNotEmpty) return title;
        final snippet = _firstCodeLine(code?.code);
        if (snippet != null) return snippet;
        return _meaningfulContent(message, genericBrackets: true) ??
            'reply_placeholder_code'.tr();
      case MessageType.location:
        final loc = message.payload?.location;
        final title = loc?.title?.trim();
        if (title != null && title.isNotEmpty) return title;
        final address = loc?.address?.trim();
        if (address != null && address.isNotEmpty) return address;
        return _meaningfulContent(message) ?? 'reply_placeholder_location'.tr();
      case MessageType.card:
        final card = message.payload?.card;
        if (card?.cardType == 'forward_record') {
          return 'chat_forward_record'.tr();
        }
        final title = card?.title?.trim();
        if (title != null && title.isNotEmpty) return title;
        final summary = card?.summary?.trim();
        if (summary != null && summary.isNotEmpty) return summary;
        return _meaningfulContent(message) ?? 'reply_placeholder_card'.tr();
      case MessageType.emoji:
        final content = message.content.trim();
        if (content.isNotEmpty) return message.content;
        final emojiCode = message.payload?.emojiCode?.trim();
        if (emojiCode != null && emojiCode.isNotEmpty) return emojiCode;
        return 'reply_placeholder_emoji'.tr();
      case MessageType.text:
      case MessageType.richText:
      case MessageType.system:
      case null:
        return message.content;
    }
  }

  /// 优先展示用户真实内容。
  ///
  /// 依次尝试 `payload.content` 与 `message.content`（后者可能是服务端写入的
  /// 历史预览），跳过空文本与历史遗留的协议占位符（如 `[code]`、`[video]`、
  /// `[dart]`、`plaintext`），无有效内容时返回 null，由调用方展示本地化占位。
  /// 文本/富文本/表情消息不走此方法（用户原文即使形如 `[code]` 也是有效内容）。
  static String? _meaningfulContent(
    ChatMessage message, {
    bool genericBrackets = false,
  }) {
    for (final candidate in [message.payload?.content, message.content]) {
      if (candidate == null) continue;
      final trimmed = candidate.trim();
      if (trimmed.isEmpty) continue;
      if (_isProtocolPlaceholder(trimmed, genericBrackets: genericBrackets)) {
        continue;
      }
      return trimmed;
    }
    return null;
  }

  /// 取代码首个非空行，避免会话列表被整段代码撑爆（UI 侧单行省略）。
  static String? _firstCodeLine(String? code) {
    if (code == null) return null;
    for (final line in code.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  /// 是否为历史遗留的协议占位符（需映射为本地化文案，而非直接展示）。
  ///
  /// [genericBrackets] 仅代码类型使用：服务端曾对无标题代码返回 `[language]`
  ///（如 `[dart]`），本地曾用 `plaintext` 做 content，需要一并识别。
  static bool _isProtocolPlaceholder(
    String trimmed, {
    bool genericBrackets = false,
  }) {
    final lower = trimmed.toLowerCase();
    const markers = {
      '[image]',
      '[audio]',
      '[voice]',
      '[voide]', // 兼容历史语音占位拼写。
      '[video]',
      '[file]',
      '[emoji]',
      '[location]',
      '[card]',
      '[system]',
      '[code]',
      '[empty]',
      // 中文历史占位。
      '[图像]',
      '[图片]',
      '[语音]',
      '[视频]',
      '[文件]',
      '[表情]',
      '[位置]',
      '[卡片]',
      '[代码]',
      '[系统消息]',
      '[系统]',
      '[空内容]',
      // 本地发送代码时曾用语言名做 content。
      'plaintext',
      '[plaintext]',
    };
    if (markers.contains(lower) || markers.contains(trimmed)) return true;
    if (genericBrackets &&
        trimmed.length >= 3 &&
        trimmed.length <= 20 &&
        RegExp(r'^\[[A-Za-z0-9_+#-]+\]$').hasMatch(trimmed)) {
      return true;
    }
    return false;
  }
}

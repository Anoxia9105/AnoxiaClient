import 'dart:convert';

import '../protocol/message/Attachment.dart';
import '../protocol/message/MessageEunm.dart';
import '../protocol/message/MessagePayload.dart';
import 'ChatMessage.dart';

class ChatFavorite {
  final int id;
  final String msgId;
  final String favoriteType;
  final String content;
  final String payload;
  final String attachments;
  final DateTime? createdAt;

  const ChatFavorite({
    required this.id,
    required this.msgId,
    required this.favoriteType,
    required this.content,
    required this.payload,
    required this.attachments,
    required this.createdAt,
  });

  factory ChatFavorite.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt']?.toString();
    return ChatFavorite(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      msgId: json['msgId']?.toString() ?? '',
      favoriteType: json['favoriteType']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      payload: json['payload']?.toString() ?? '',
      attachments: json['attachments']?.toString() ?? '',
      createdAt: rawCreatedAt != null && rawCreatedAt.isNotEmpty
          ? DateTime.tryParse(rawCreatedAt)
          : null,
    );
  }

  String get typeLabel {
    final upper = favoriteType.toUpperCase();
    if (upper.isEmpty) return 'TEXT';
    return upper;
  }

  MessageType get messageType {
    final raw = favoriteType.trim();
    if (raw.isNotEmpty) {
      final byNameOrCode = MessageType.fromCode(raw);
      if (byNameOrCode != MessageType.text || raw.toUpperCase() == 'TEXT') {
        return byNameOrCode;
      }

      final asInt = int.tryParse(raw);
      if (asInt != null) {
        return MessageType.fromCode(asInt);
      }
    }

    final att = _buildAttachments();
    if (att.isNotEmpty) {
      final hasImage = att.any((e) => e.isImage);
      return hasImage ? MessageType.image : MessageType.file;
    }

    return MessageType.text;
  }

  String get summary {
    final text = content.trim();
    if (text.isNotEmpty) return text;

    final payloadText = _extractPayloadText();
    if (payloadText.isNotEmpty) return payloadText;

    if (attachments.trim().isNotEmpty) {
      return '[$typeLabel]';
    }

    return '[empty]';
  }

  String get detailText {
    final text = content.trim();
    final payloadText = _extractPayloadText();

    // 详情页优先展示信息量更完整的文本，避免仅显示被截断的 content。
    if (payloadText.isNotEmpty && payloadText.length > text.length) {
      return payloadText;
    }

    if (text.isNotEmpty) return text;
    if (payloadText.isNotEmpty) return payloadText;

    if (payload.trim().isNotEmpty) return payload;
    if (attachments.trim().isNotEmpty) return attachments;

    return '';
  }

  String _extractPayloadText() {
    if (payload.trim().isEmpty) return '';

    try {
      final decoded = _decodeMaybeJson(payload);

      if (decoded is Map<String, dynamic>) {
        for (final key in ['content', 'text', 'title', 'url']) {
          final value = decoded[key]?.toString().trim();
          if (value != null && value.isNotEmpty) return value;
        }

        final delta = decoded['delta'];
        if (delta is List) {
          final joined = delta
              .map((e) =>
                  e is Map<String, dynamic> ? e['insert']?.toString() ?? '' : '')
              .join('')
              .trim();
          if (joined.isNotEmpty) return joined;
        }
      }

      if (decoded is List) {
        final joined = decoded
            .map((e) =>
                e is Map<String, dynamic> ? e['insert']?.toString() ?? '' : '')
            .join('')
            .trim();
        if (joined.isNotEmpty) return joined;
      }
    } catch (_) {
      // ignore parse errors and fallback to raw payload
    }

    return '';
  }

  ChatMessage toChatMessage() {
    final resolvedType = messageType;
    final resolvedPayload = _buildPayload(resolvedType);
    final resolvedAttachments = _buildAttachments();

    return ChatMessage(
      messageId: msgId,
      messageType: resolvedType,
      content: content,
      payload: resolvedPayload,
      attachments: resolvedAttachments,
    );
  }

  MessagePayload _buildPayload(MessageType type) {
    final raw = payload.trim();
    if (raw.isEmpty) {
      return MessagePayload(content: content.trim());
    }

    try {
      final decoded = _decodeMaybeJson(raw);

      if (decoded is Map<String, dynamic>) {
        final parsed = MessagePayload.fromJson(decoded);
        final parsedContent = parsed.content?.trim() ?? '';
        if (parsedContent.isNotEmpty || content.trim().isEmpty) {
          return parsed;
        }
        return MessagePayload(
          content: content.trim(),
          quillDelta: parsed.quillDelta,
          replyTo: parsed.replyTo,
          mentions: parsed.mentions,
          markdown: parsed.markdown,
          emojiCode: parsed.emojiCode,
        );
      }

      if (decoded is List && type == MessageType.quill) {
        return MessagePayload(
          content: content.trim(),
          quillDelta: jsonEncode(decoded),
        );
      }
    } catch (_) {
      // ignore parse errors and fallback below
    }

    return MessagePayload(content: content.trim());
  }

  List<Attachment> _buildAttachments() {
    final raw = attachments.trim();
    if (raw.isNotEmpty) {
      final fromAttachments = _parseAttachmentsDynamic(_decodeMaybeJson(raw));
      if (fromAttachments.isNotEmpty) return fromAttachments;
    }

    final payloadRaw = payload.trim();
    if (payloadRaw.isNotEmpty) {
      final fromPayload = _parseAttachmentsDynamic(_decodeMaybeJson(payloadRaw));
      if (fromPayload.isNotEmpty) return fromPayload;
    }

    return const [];
  }

  dynamic _decodeMaybeJson(dynamic source) {
    dynamic current = source;
    for (var i = 0; i < 3; i++) {
      if (current is! String) return current;
      final text = current.trim();
      if (text.isEmpty) return text;

      try {
        current = jsonDecode(text);
      } catch (_) {
        return current;
      }
    }
    return current;
  }

  List<Attachment> _parseAttachmentsDynamic(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Attachment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final nestedCandidates = [
        decoded['attachments'],
        decoded['files'],
        decoded['list'],
      ];
      for (final candidate in nestedCandidates) {
        final nested = _parseAttachmentsDynamic(_decodeMaybeJson(candidate));
        if (nested.isNotEmpty) return nested;
      }

      final hasUrl = (decoded['url']?.toString().trim().isNotEmpty ?? false);
      if (hasUrl) {
        return [
          Attachment.fromJson({
            'url': decoded['url'],
            'id': decoded['id'],
            'name': decoded['name'] ?? decoded['fileName'],
            'size': decoded['size'],
            'type': decoded['type'] ?? decoded['ext'],
          }),
        ];
      }
    }

    return const [];
  }
}

import 'dart:convert';

import '../protocol/message/Attachment.dart';
import '../protocol/message/MessageEunm.dart';
import '../protocol/message/MessagePayload.dart';
import 'ChatMessage.dart';

class ChatFavorite {
  final int id;
  final String msgId;
  final String favoriteType;
  final int? senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final String payload;
  final String attachments;
  final DateTime? createdAt;

  const ChatFavorite({
    required this.id,
    required this.msgId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.favoriteType,
    required this.content,
    required this.payload,
    required this.attachments,
    required this.createdAt,
  });

  factory ChatFavorite.fromJson(Map<String, dynamic> json) {
    final senderInfo = _extractSenderInfo(json);

    final rawCreatedAt =
        json['createdAt']?.toString() ?? json['created_at']?.toString();
    return ChatFavorite(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      msgId: json['msgId']?.toString() ?? json['msg_id']?.toString() ?? '',
      senderId: senderInfo.senderId,
      senderName: senderInfo.senderName,
      senderAvatar: senderInfo.senderAvatar,
      favoriteType:
          json['favoriteType']?.toString() ?? json['favorite_type']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      payload: json['payload']?.toString() ?? '',
      attachments: json['attachments']?.toString() ?? '',
      createdAt: rawCreatedAt != null && rawCreatedAt.isNotEmpty
          ? DateTime.tryParse(rawCreatedAt)
          : null,
    );
  }

  String get typeLabel {
    return messageType.name.toUpperCase();
  }

  String get senderDisplayName {
    final text = senderName.trim();
    if (text.isNotEmpty) return text;
    if (senderId != null) return 'User #$senderId';
    return '';
  }

  MessageType get messageType {
    final raw = favoriteType.trim();
    final explicitType = _parseType(raw);

    if (explicitType != null && explicitType != MessageType.text) {
      return explicitType;
    }

    final inferredPayloadType = _inferPayloadType();
    if (inferredPayloadType != null) {
      return inferredPayloadType;
    }

    if (explicitType != null) {
      return explicitType;
    }

    final att = _buildAttachments();
    if (att.isNotEmpty) {
      final hasImage = att.any((e) => e.isImage);
      return hasImage ? MessageType.image : MessageType.file;
    }

    return MessageType.text;
  }

  MessageType? _parseType(String raw) {
    if (raw.isEmpty) return null;

    final byName = MessageType.fromCode(raw);
    final upper = raw.toUpperCase();
    final hasNameMatch = MessageType.values.any((e) => e.name.toUpperCase() == upper);
    if (hasNameMatch) return byName;

    final asInt = int.tryParse(raw);
    if (asInt != null) {
      return MessageType.fromCode(asInt);
    }

    return null;
  }

  MessageType? _inferPayloadType() {
    final payloadRaw = payload.trim();
    if (payloadRaw.isNotEmpty) {
      final decoded = _decodeMaybeJson(payloadRaw);
      if (_containsQuillDelta(decoded)) {
        return MessageType.quill;
      }
    }

    final att = _buildAttachments();
    if (att.isNotEmpty) {
      final hasImage = att.any((e) => e.isImage);
      return hasImage ? MessageType.image : MessageType.file;
    }

    return null;
  }

  bool _containsQuillDelta(dynamic decoded) {
    if (decoded is List) {
      return decoded.any((e) => e is Map && e.containsKey('insert'));
    }

    if (decoded is Map<String, dynamic>) {
      final quillDelta = decoded['quillDelta'];
      final delta = decoded['delta'];
      final ops = decoded['ops'];
      if (quillDelta != null || delta != null || ops != null) {
        return true;
      }
    }

    return false;
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
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
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
        final normalizedQuillDelta = _extractQuillDeltaString(decoded);
        final parsedContent = parsed.content?.trim() ?? '';
        if (parsedContent.isNotEmpty || content.trim().isEmpty) {
          return MessagePayload(
            content: parsed.content,
            quillDelta: parsed.quillDelta ?? normalizedQuillDelta,
            replyTo: parsed.replyTo,
            mentions: parsed.mentions,
            markdown: parsed.markdown,
            emojiCode: parsed.emojiCode,
          );
        }
        return MessagePayload(
          content: content.trim(),
          quillDelta: parsed.quillDelta ?? normalizedQuillDelta,
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

  String? _extractQuillDeltaString(Map<String, dynamic> decoded) {
    final candidates = [decoded['quillDelta'], decoded['delta'], decoded['ops']];
    for (final candidate in candidates) {
      if (candidate == null) continue;
      if (candidate is String && candidate.trim().isNotEmpty) return candidate;
      if (candidate is List || candidate is Map<String, dynamic>) {
        return jsonEncode(candidate);
      }
    }
    return null;
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

  static _SenderInfo _extractSenderInfo(Map<String, dynamic> json) {
    final senderId = _readInt(
      json,
      keys: [
        'senderId',
        'sender_id',
        'fromUserId',
        'from_user_id',
        'fromId',
        'userId',
      ],
    );

    String senderName = _readString(
      json,
      keys: [
        'senderName',
        'sender_name',
        'fromUserName',
        'from_user_name',
        'nickName',
        'nick_name',
        'nickname',
        'userName',
        'user_name',
      ],
    );

    String senderAvatar = _readString(
      json,
      keys: [
        'senderAvatar',
        'sender_avatar',
        'fromUserAvatar',
        'from_user_avatar',
        'avatar',
        'avatarUrl',
        'avatar_url',
      ],
    );

    final payloadRaw = json['payload']?.toString() ?? '';
    if (payloadRaw.trim().isNotEmpty) {
      final payloadDecoded = _decodeStatic(payloadRaw);
      if (payloadDecoded is Map<String, dynamic>) {
        senderName = senderName.isNotEmpty
            ? senderName
            : _readString(
                payloadDecoded,
                keys: [
                  'senderName',
                  'sender_name',
                  'fromUserName',
                  'from_user_name',
                  'nickName',
                  'nick_name',
                  'nickname',
                  'userName',
                  'user_name',
                ],
              );
        senderAvatar = senderAvatar.isNotEmpty
            ? senderAvatar
            : _readString(
                payloadDecoded,
                keys: [
                  'senderAvatar',
                  'sender_avatar',
                  'fromUserAvatar',
                  'from_user_avatar',
                  'avatar',
                  'avatarUrl',
                  'avatar_url',
                ],
              );
      }
    }

    return _SenderInfo(
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
    );
  }

  static int? _readInt(Map<String, dynamic> source, {required List<String> keys}) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static String _readString(Map<String, dynamic> source, {required List<String> keys}) {
    for (final key in keys) {
      final value = source[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static dynamic _decodeStatic(dynamic source) {
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
}

class _SenderInfo {
  final int? senderId;
  final String senderName;
  final String senderAvatar;

  const _SenderInfo({
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
  });
}

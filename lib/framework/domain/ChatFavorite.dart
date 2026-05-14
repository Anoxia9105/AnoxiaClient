import 'dart:convert';

import '../protocol/message/Attachment.dart';
import '../protocol/message/MessageEunm.dart';
import '../protocol/message/MessagePayload.dart';
import 'ChatMessage.dart';

/// 收藏消息模型
///
/// 表示用户收藏的单条消息，包含原始消息内容和元数据。
/// 支持从多种数据格式（snake_case/camelCase、嵌套 JSON）自动解析，
/// 并可转换为标准 [ChatMessage] 格式进行展示。
class ChatFavorite {
  /// 收藏记录主键ID
  final int id;

  /// 对应消息ID
  final String msgId;

  /// 消息类型标识
  final String favoriteType;

  /// 发送者用户ID
  final int? senderId;

  /// 发送者昵称
  final String senderName;

  /// 发送者头像
  final String senderAvatar;

  /// 消息文本内容
  final String content;

  /// 消息负载（JSON 字符串，可能包含 Quill Delta 等结构化数据）
  final String payload;

  /// 附件列表（JSON 字符串）
  final String attachments;

  /// 收藏时间
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

  /// 从 JSON 数据构造 [ChatFavorite] 实例
  ///
  /// 自动兼容多种命名风格（snake_case、camelCase）和数据类型（String/Map/List）
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

  /// 获取消息类型的显示标签
  String get typeLabel {
    return messageType.name.toUpperCase();
  }

  /// 获取发送者显示名称
  ///
  /// 优先级：昵称 > "User #userId" > 空字符串
  String get senderDisplayName {
    final text = senderName.trim();
    if (text.isNotEmpty) return text;
    if (senderId != null) return 'User #$senderId';
    return '';
  }

  /// 解析消息类型
  ///
  /// 按以下优先级推断：显式类型标识 > Payload 推断 > 附件推断 > 默认文本类型
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

  /// 从类型字符串解析 [MessageType]
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

  /// 从 Payload 内容推断消息类型
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

  /// 检查解码后的数据是否包含 Quill Delta 格式
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

  /// 获取收藏内容的摘要文本
  ///
  /// 优先级：content > payload 文本 > 附件类型标签 > "[empty]"
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

  /// 获取收藏内容的完整详情文本
  ///
  /// 与 [summary] 的区别：此方法优先展示信息量更完整的长文本
  String get detailText {
    final text = content.trim();
    final payloadText = _extractPayloadText();

    if (payloadText.isNotEmpty && payloadText.length > text.length) {
      return payloadText;
    }

    if (text.isNotEmpty) return text;
    if (payloadText.isNotEmpty) return payloadText;

    if (payload.trim().isNotEmpty) return payload;
    if (attachments.trim().isNotEmpty) return attachments;

    return '';
  }

  /// 从 Payload 中提取可读的文本内容
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
      // 解析失败时降级返回空字符串
    }

    return '';
  }

  /// 转换为标准 [ChatMessage] 格式
  ///
  /// 用于在消息详情页或转发场景中复用消息渲染逻辑
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

  /// 根据消息类型构建 [MessagePayload]
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
      // 解析失败时降级构建基础 Payload
    }

    return MessagePayload(content: content.trim());
  }

  /// 从 Map 中提取 Quill Delta 字符串
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

  /// 构建附件列表
  ///
  /// 优先从 attachments 字段解析，失败时从 payload 中提取
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

  /// 递归尝试将字符串解码为 JSON 对象
  ///
  /// 最多尝试 3 次，支持嵌套的 JSON 字符串
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

  /// 动态解析附件列表
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

  /// 从 JSON 中提取发送者信息
  ///
  /// 兼容多种字段命名风格，优先取顶层字段，其次从 payload 中查找
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

  /// 从多个候选键中读取整数值的辅助方法
  static int? _readInt(Map<String, dynamic> source, {required List<String> keys}) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// 从多个候选键中读取字符串值的辅助方法
  static String _readString(Map<String, dynamic> source, {required List<String> keys}) {
    for (final key in keys) {
      final value = source[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  /// 静态版本的 JSON 解码方法
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

/// 发送者信息的内部封装类
///
/// 仅用于 [ChatFavorite] 内部数据解析，不对外暴露
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

import 'dart:convert';

import 'package:anoxia/framework/protocol/message/RoomMessage.dart';

import '../protocol/message/Attachment.dart';
import '../protocol/message/MessageEunm.dart';
import '../protocol/message/MessagePayload.dart';

/// 聊天消息模型
///
/// 表示聊天会话中的单条消息，包含消息内容、发送者信息、附件和元数据。
/// 支持 JSON 序列化/反序列化，并与 WebSocket 协议层无缝对接。
class ChatMessage {
  /// 服务器分配的消息唯一标识
  final String? messageId;

  /// 客户端生成的消息ID（用于消息去重和本地索引）
  final String? clientMsgId;

  /// 所属聊天室ID
  final String? roomId;

  /// 发送者用户ID
  final int? senderId;

  /// 发送者昵称
  final String? senderName;

  /// 发送者头像 URL
  final String? senderAvatar;

  /// 消息类型
  final MessageType? messageType;

  /// 消息文本内容
  final String content;

  /// 消息负载（支持富文本、引用、@提及等扩展信息）
  final MessagePayload? payload;

  /// 文件附件列表
  final List<Attachment> attachments;

  /// 扩展字段（用于传递非标准化的业务数据）
  final Map<String, dynamic> extra;

  /// 消息状态（已读/未读等）
  final MessageState? messageStatus;

  /// 消息投递状态
  final DeliveryStatus deliveryStatus;

  /// 消息时间戳（毫秒）
  final int? timestamp;

  /// 消息序号（用于消息排序和水位线同步）
  final int? seq;

  ChatMessage({
    this.messageId,
    this.clientMsgId,
    this.roomId,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    this.messageType,
    this.payload,
    this.messageStatus,
    this.timestamp,
    this.seq,
    this.content = '',
    this.attachments = const [],
    this.extra = const {},
    this.deliveryStatus = DeliveryStatus.sent,
  });

  /// 创建当前实例的变体副本
  ///
  /// 专门用于更新消息状态和序号，避免重置其他字段
  ChatMessage copyWith({
    String? messageId,
    String? clientMsgId,
    DeliveryStatus? deliveryStatus,
    int? seq,
    MessageState? messageStatus,
    int? timestamp,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      clientMsgId: clientMsgId ?? this.clientMsgId,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      messageType: messageType,
      content: content,
      payload: payload,
      attachments: attachments,
      extra: extra,
      messageStatus: messageStatus ?? this.messageStatus,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      timestamp: timestamp ?? this.timestamp,
      seq: seq ?? this.seq,
    );
  }

  /// 从 JSON 数据构造 [ChatMessage] 实例
  ///
  /// 自动处理 payload、attachments、extra 字段可能为 String 或 Map 的兼容场景
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // 1. 预处理 payload (可能是 String 也可能是 Map)
    dynamic rawPayload = _decodeMaybeJson(json['payload']);
    if (rawPayload is String && rawPayload.isNotEmpty) {
      rawPayload = null;
    }

    // 2. 预处理 attachments (可能是 String 也可能是 List)
    dynamic rawAttachments = _decodeMaybeJson(json['attachments']);
    if (rawAttachments is String && rawAttachments.isNotEmpty) {
      rawAttachments = null;
    }

    // 3. 预处理 extra (可能是 String 也可能是 Map)
    dynamic rawExtra = _decodeMaybeJson(json['extra'] ?? json['properties']);
    if (rawExtra is String && rawExtra.isNotEmpty) {
      rawExtra = null;
    }

    final payload = rawPayload is Map
        ? MessagePayload.fromJson(Map<String, dynamic>.from(rawPayload))
        : null;
    final attachments = _extractAttachments(rawAttachments, rawPayload);
    final content = _resolveContent(json, payload);

    return ChatMessage(
      messageId: json['messageId']?.toString(),
      clientMsgId: (json['clientMsgId'] ?? json['clientMessageId'])?.toString(),
      roomId: json['roomId']?.toString(),
      senderId: json['senderId'] != null
          ? int.tryParse(json['senderId'].toString())
          : null,
      senderName: json['senderName']?.toString(),
      senderAvatar: json['senderAvatar']?.toString(),
      messageType: MessageType.fromCode(json['messageType']),
      content: content,

      // 使用处理后的 rawPayload
      payload: payload,

      // 使用处理后的 rawAttachments
      attachments: attachments,

      // 使用处理后的 rawExtra
      extra: rawExtra is Map ? Map<String, dynamic>.from(rawExtra) : {},

      messageStatus: MessageState.from(json['messageStatus']),
      deliveryStatus: DeliveryStatus.sent,
      timestamp: json['timestamp'] != null
          ? int.tryParse(json['timestamp'].toString())
          : int.tryParse((json['serverTimestamp'] ?? '').toString()),
      seq: json['seq'] != null ? int.tryParse(json['seq'].toString()) : null,
    );
  }

  /// 从 [RoomMessage] 实例构造 [ChatMessage] 实例（V5 协议对齐）
  ///
  /// V5 协议不再传输 senderName/senderAvatar/state/status（由客户端本地管理）
  static ChatMessage fromRoomMessage(RoomMessage msg) {
    return ChatMessage(
      messageId: msg.messageId.isEmpty ? null : msg.messageId,
      clientMsgId: msg.clientMsgId,
      roomId: msg.roomId,
      senderId: msg.senderId == 0 ? null : msg.senderId,
      // senderName / senderAvatar 不在 V5 协议中，需从用户缓存补充
      senderName: null,
      senderAvatar: null,
      messageType: msg.messageType,
      content: msg.payload?.content ?? '',
      payload: msg.payload,
      attachments: msg.attachments,
      extra: msg.extra,
      messageStatus: null, // V5 不在消息体中携带状态
      deliveryStatus: DeliveryStatus.sent,
      timestamp: msg.timestamp == 0 ? null : msg.timestamp,
      seq: msg.seq,
    );
  }

  static dynamic _decodeMaybeJson(dynamic source) {
    dynamic current = source;
    for (var i = 0; i < 3; i++) {
      if (current is! String) return current;
      final text = current.trim();
      if (text.isEmpty) return null;
      try {
        current = jsonDecode(text);
      } catch (_) {
        return current;
      }
    }
    return current;
  }

  static String _resolveContent(
    Map<String, dynamic> json,
    MessagePayload? payload,
  ) {
    final direct = json['content']?.toString().trim() ?? '';
    if (direct.isNotEmpty) return direct;
    return payload?.content ?? '';
  }

  static List<Attachment> _extractAttachments(
    dynamic rawAttachments,
    dynamic rawPayload,
  ) {
    final fromTopLevel = _parseAttachments(rawAttachments);
    if (fromTopLevel.isNotEmpty) return fromTopLevel;

    final fromPayload = _parseAttachments(rawPayload);
    if (fromPayload.isNotEmpty) return fromPayload;

    return const [];
  }

  static List<Attachment> _parseAttachments(dynamic value) {
    final decoded = _decodeMaybeJson(value);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Attachment.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.url?.isNotEmpty == true)
          .toList();
    }

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      for (final key in const [
        'attachments',
        'files',
        'list',
        'image',
        'audio',
        'video',
        'file',
        'emoji',
        'asset',
        'cover',
      ]) {
        final nested = _parseAttachments(map[key]);
        if (nested.isNotEmpty) return nested;
      }

      final hasUrl = map['url']?.toString().trim().isNotEmpty == true;
      if (hasUrl) return [Attachment.fromJson(map)];
    }

    return const [];
  }
}

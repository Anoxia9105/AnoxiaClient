/// 聊天消息领域模型。
///
/// 表示一条聊天消息的完整数据，包含消息 ID、内容、发送者、
/// 消息类型、投递状态等属性，支持 JSON 反序列化和 RoomMessage 转换。
import 'dart:convert';

import 'package:anoxia/framework/protocol/message/room_message.dart';

import '../protocol/message/message_enum.dart';
import '../protocol/message/message_payload.dart';

/// 聊天消息数据类。
class ChatMessage {
  /// 服务端消息 ID。
  final String? messageId;

  /// 客户端消息 ID。
  final String? clientMsgId;

  /// 聊天房间 ID。
  final String? roomId;

  /// 发送者 ID。
  final int? senderId;

  /// 消息类型。
  final MessageType? messageType;

  /// 消息文本内容。
  final String content;

  /// 消息载荷，包含富文本、附件等扩展数据。
  final MessagePayload? payload;

  /// 消息扩展属性。
  final Map<String, String> properties;

  /// Local UI delivery state. It is not part of the backend RoomMessage.
  final DeliveryStatus deliveryStatus;

  /// 消息时间戳。
  final int? timestamp;

  /// 消息序号。
  final int? seq;

  ChatMessage({
    this.messageId,
    this.clientMsgId,
    this.roomId,
    this.senderId,
    this.messageType,
    this.payload,
    this.timestamp,
    this.seq,
    this.content = '',
    this.properties = const {},
    this.deliveryStatus = DeliveryStatus.sent,
  });

  /// 创建消息的副本，可选择性替换部分字段。
  ChatMessage copyWith({
    String? messageId,
    String? clientMsgId,
    DeliveryStatus? deliveryStatus,
    int? seq,
    int? timestamp,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      clientMsgId: clientMsgId ?? this.clientMsgId,
      roomId: roomId,
      senderId: senderId,
      messageType: messageType,
      content: content,
      payload: payload,
      properties: properties,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      timestamp: timestamp ?? this.timestamp,
      seq: seq ?? this.seq,
    );
  }

  /// 从 JSON 数据创建消息对象。
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    dynamic rawPayload = _decodeMaybeJson(json['payload']);
    if (rawPayload is String && rawPayload.isNotEmpty) {
      rawPayload = null;
    }

    dynamic rawExtra = _decodeMaybeJson(json['extra'] ?? json['properties']);
    if (rawExtra is String && rawExtra.isNotEmpty) {
      rawExtra = null;
    }

    final payload = rawPayload is Map
        ? MessagePayload.fromJson(Map<String, dynamic>.from(rawPayload))
        : null;
    final content = _resolveContent(json, payload);

    return ChatMessage(
      messageId: json['messageId']?.toString(),
      clientMsgId: (json['clientMsgId'] ?? json['clientMessageId'])?.toString(),
      roomId: json['roomId']?.toString(),
      senderId: json['senderId'] != null
          ? int.tryParse(json['senderId'].toString())
          : null,
      messageType: MessageType.fromCode(json['messageType']),
      content: content,
      payload: payload,
      properties: rawExtra is Map ? Map<String, String>.from(rawExtra) : {},
      timestamp: json['timestamp'] != null
          ? int.tryParse(json['timestamp'].toString())
          : int.tryParse((json['serverTimestamp'] ?? '').toString()),
      seq: json['seq'] != null ? int.tryParse(json['seq'].toString()) : null,
    );
  }

  /// 从 [RoomMessage] 协议对象创建消息对象。
  static ChatMessage fromRoomMessage(RoomMessage msg) {
    return ChatMessage(
      messageId: msg.messageId.isEmpty ? null : msg.messageId,
      clientMsgId: msg.clientMsgId,
      roomId: msg.roomId,
      senderId: msg.senderId == 0 ? null : msg.senderId,
      messageType: msg.messageType,
      content: msg.payload?.content ?? '',
      payload: msg.payload,
      properties: msg.properties,
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

  @override
  String toString() {
    return 'ChatMessage{'
        'messageId: $messageId, '
        'clientMsgId: $clientMsgId, '
        'roomId: $roomId, '
        'senderId: $senderId, '
        'messageType: $messageType, '
        'content: "$content", '
        'payload: ${payload != null ? "(MessagePayload)" : "null"}, '
        'properties: $properties, '
        'deliveryStatus: $deliveryStatus, '
        'timestamp: $timestamp, '
        'seq: $seq'
        '}';
  }
}

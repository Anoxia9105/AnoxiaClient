import 'dart:convert';

import 'package:anoxia/framework/protocol/message/RoomMessage.dart';

import '../protocol/message/MessageEunm.dart';
import '../protocol/message/MessagePayload.dart';

class ChatMessage {
  final String? messageId;
  final String? clientMsgId;
  final String? roomId;
  final int? senderId;
  final MessageType? messageType;
  final String content;
  final MessagePayload? payload;
  final Map<String, String> properties;

  /// Local UI delivery state. It is not part of the backend RoomMessage.
  final DeliveryStatus deliveryStatus;

  final int? timestamp;
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

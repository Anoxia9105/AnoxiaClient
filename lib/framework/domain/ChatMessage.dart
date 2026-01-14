import 'dart:convert';
import '../protocol/message/Attachment.dart';
import '../protocol/message/MessageEunm.dart';
import '../protocol/message/MessagePayload.dart';

class ChatMessage {
  final String? messageId;
  final String? roomId;
  final int? senderId;
  final MessageType? messageType;
  final String content;
  final MessagePayload? payload;
  final List<Attachment> attachments;
  final Map<String, dynamic> extra;
  final MessageState? messageStatus;
  final int? timestamp;
  final int? seq;

  ChatMessage({
    this.messageId,
    this.roomId,
    this.senderId,
    this.messageType,
    this.payload,
    this.messageStatus,
    this.timestamp,
    this.seq,
    this.content = '',
    this.attachments = const [],
    this.extra = const {},
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // 1. 预处理 payload (可能是 String 也可能是 Map)
    dynamic rawPayload = json['payload'];
    if (rawPayload is String && rawPayload.isNotEmpty) {
      try {
        rawPayload = jsonDecode(rawPayload);
      } catch (_) {
        rawPayload = null;
      }
    }

    // 2. 预处理 attachments (可能是 String 也可能是 List)
    dynamic rawAttachments = json['attachments'];
    if (rawAttachments is String && rawAttachments.isNotEmpty) {
      try {
        rawAttachments = jsonDecode(rawAttachments);
      } catch (_) {
        rawAttachments = null;
      }
    }

    // 3. 预处理 extra (可能是 String 也可能是 Map)
    dynamic rawExtra = json['extra'];
    if (rawExtra is String && rawExtra.isNotEmpty) {
      try {
        rawExtra = jsonDecode(rawExtra);
      } catch (_) {
        rawExtra = null;
      }
    }

    return ChatMessage(
      messageId: json['messageId']?.toString(),
      roomId: json['roomId']?.toString(),
      senderId: json['senderId'] != null ? int.tryParse(json['senderId'].toString()) : null,
      messageType: MessageType.fromCode(json["messageType"] ?? 5),
      content: json['content']?.toString() ?? '',

      // 使用处理后的 rawPayload
      payload: rawPayload != null && rawPayload is Map<String, dynamic>
          ? MessagePayload.fromJson(rawPayload)
          : null,

      // 使用处理后的 rawAttachments
      attachments: (rawAttachments is List)
          ? rawAttachments.map((e) => Attachment.fromJson(e)).toList()
          : [],

      // 使用处理后的 rawExtra
      extra: (rawExtra is Map<String, dynamic>) ? rawExtra : {},

      messageStatus: MessageState.from(json['messageStatus']),
      timestamp: json['timestamp'] != null ? int.tryParse(json['timestamp'].toString()) : null,
      seq: json['seq'] != null ? int.tryParse(json['seq'].toString()) : null,
    );
  }
}
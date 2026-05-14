import 'dart:convert';

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
    DeliveryStatus? deliveryStatus,
    int? seq,
    MessageState? messageStatus,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      clientMsgId: clientMsgId,
      roomId: roomId,
      senderId: senderId,
      messageType: messageType,
      content: content,
      payload: payload,
      attachments: attachments,
      extra: extra,
      messageStatus: messageStatus ?? this.messageStatus,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      timestamp: timestamp,
      seq: seq ?? this.seq,
    );
  }

  /// 从 JSON 数据构造 [ChatMessage] 实例
  ///
  /// 自动处理 payload、attachments、extra 字段可能为 String 或 Map 的兼容场景
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
      clientMsgId: json['clientMsgId']?.toString(),
      roomId: json['roomId']?.toString(),
      senderId: json['senderId'] != null
          ? int.tryParse(json['senderId'].toString())
          : null,
      senderName: json['senderName']?.toString(),
      senderAvatar: json['senderAvatar']?.toString(),
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
      deliveryStatus: DeliveryStatus.sent,
      timestamp: json['timestamp'] != null
          ? int.tryParse(json['timestamp'].toString())
          : null,
      seq: json['seq'] != null ? int.tryParse(json['seq'].toString()) : null,
    );
  }
}

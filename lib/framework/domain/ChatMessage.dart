import 'dart:convert';

import 'package:anoxia/framework/protocol/message/RoomMessage.dart';

import '../protocol/message/MessageEunm.dart';
import '../protocol/message/MessagePayload.dart';

/// 聊天消息模型
///
/// 用于表示应用内的单条聊天消息，支持：
/// - 消息基础信息（ID、房间、发送者、类型、内容、时间戳等）
/// - 富文本/媒体载荷（[payload]）
/// - 扩展字段（[extra]）
/// - 消息状态（发送中、已读、未读等）
/// - 从 JSON 解析（[fromJson]）和从 RoomMessage 转换（[fromRoomMessage]）
class ChatMessage {
  /// 服务端生成的消息唯一标识（可能为空，如本地暂存消息）
  final String? messageId;

  /// 客户端生成的消息唯一标识，用于去重和本地缓存
  final String? clientMsgId;

  /// 所属会话房间 ID
  final String? roomId;

  /// 发送者用户 ID
  final int? senderId;

  /// 消息类型（文本、图片、语音、视频等），来自枚举 [MessageType]
  final MessageType? messageType;

  /// 消息文本内容（纯文本，对于媒体消息可能为空，具体内容在 payload 中）
  final String content;

  /// 消息载荷，包含富文本、附件、引用回复等结构化数据
  final MessagePayload? payload;

  /// 扩展字段，用于存放业务自定义数据（如 @ 成员、消息来源等）
  final Map<String, dynamic> extra;

  /// 消息状态（发送中、发送失败、已送达、已读等）
  final MessageState? messageStatus;

  /// 投递状态（一般用于本地发送确认，默认为已发送）
  final DeliveryStatus deliveryStatus;

  /// 消息时间戳（毫秒），通常为服务端时间
  final int? timestamp;

  /// 消息在房间内的序列号（用于排序，由服务端分配）
  final int? seq;

  /// 构造函数
  ///
  /// [deliveryStatus] 默认为 [DeliveryStatus.sent]，[extra] 默认为空 Map
  ChatMessage({
    this.messageId,
    this.clientMsgId,
    this.roomId,
    this.senderId,
    this.messageType,
    this.payload,
    this.messageStatus,
    this.timestamp,
    this.seq,
    this.content = '',
    this.extra = const {},
    this.deliveryStatus = DeliveryStatus.sent,
  });

  /// 复制当前对象并更新指定字段（用于状态更新，如发送成功后更新 messageId 等）
  ///
  /// 可更新的字段：messageId, clientMsgId, deliveryStatus, seq, messageStatus, timestamp
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
      messageType: messageType,
      content: content,
      payload: payload,
      extra: extra,
      messageStatus: messageStatus ?? this.messageStatus,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      timestamp: timestamp ?? this.timestamp,
      seq: seq ?? this.seq,
    );
  }

  /// 从 JSON 映射创建 [ChatMessage] 实例
  ///
  /// 支持字段别名：
  /// - `clientMessageId` 作为 `clientMsgId` 的备用键
  /// - `extra` 或 `properties` 作为扩展字段
  /// - 时间戳优先使用 `timestamp`，若不存在则尝试 `serverTimestamp`
  ///
  /// 自动处理嵌套 JSON 字符串的解析（如 payload 可能为字符串形式的 JSON）。
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // 解析 payload 字段（可能是 JSON 字符串）
    dynamic rawPayload = _decodeMaybeJson(json['payload']);
    if (rawPayload is String && rawPayload.isNotEmpty) {
      rawPayload = null;
    }

    // 解析 extra / properties 字段
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
      extra: rawExtra is Map ? Map<String, dynamic>.from(rawExtra) : {},
      messageStatus: MessageState.from(json['messageStatus']),
      deliveryStatus: DeliveryStatus.sent, // 从本地发送时默认已发送，服务端返回时此字段无意义
      timestamp: json['timestamp'] != null
          ? int.tryParse(json['timestamp'].toString())
          : int.tryParse((json['serverTimestamp'] ?? '').toString()),
      seq: json['seq'] != null ? int.tryParse(json['seq'].toString()) : null,
    );
  }

  /// 从 [RoomMessage]（协议层消息对象）转换为 [ChatMessage]
  ///
  /// 主要用于服务端推送的消息转换为 UI 层使用的模型。
  static ChatMessage fromRoomMessage(RoomMessage msg) {
    return ChatMessage(
      messageId: msg.messageId.isEmpty ? null : msg.messageId,
      clientMsgId: msg.clientMsgId,
      roomId: msg.roomId,
      senderId: msg.senderId == 0 ? null : msg.senderId,
      messageType: msg.messageType,
      content: msg.payload?.content ?? '',
      payload: msg.payload,
      extra: msg.extra,
      messageStatus: null,
      deliveryStatus: DeliveryStatus.sent,
      timestamp: msg.timestamp == 0 ? null : msg.timestamp,
      seq: msg.seq,
    );
  }

  /// 尝试多次解码 JSON 字符串（防止嵌套多层转义）
  ///
  /// 最多递归解码 3 次，若解码后仍为字符串且非空，则返回原字符串；
  /// 若解码成功则返回解码后的对象（Map/List），否则返回原值。
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

  /// 从 JSON 和已解析的 payload 中提取消息文本内容
  ///
  /// 优先级：JSON 中的 `content` 字段 > payload 中的 `content` 字段
  static String _resolveContent(
    Map<String, dynamic> json,
    MessagePayload? payload,
  ) {
    final direct = json['content']?.toString().trim() ?? '';
    if (direct.isNotEmpty) return direct;
    return payload?.content ?? '';
  }

  /// 返回对象的字符串表示，便于调试和日志输出
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
        'extra: $extra, '
        'messageStatus: $messageStatus, '
        'deliveryStatus: $deliveryStatus, '
        'timestamp: $timestamp, '
        'seq: $seq'
        '}';
  }
}
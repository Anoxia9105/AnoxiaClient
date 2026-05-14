import '../IPacket.dart';
import 'Attachment.dart';
import 'MessageEunm.dart';
import 'MessagePayload.dart';
import 'package:flutter/foundation.dart';

/// 聊天室消息
///
/// 通过 WebSocket 传输的完整消息模型。
/// 包含消息发送者信息、消息内容、附件和消息状态。
@immutable
class RoomMessage implements IPacket {
  /// 聊天室ID
  final String roomId;

  /// 客户端生成的消息ID
  final String? clientMsgId;

  /// 目标用户ID（单聊时使用）
  final int? targetId;

  /// 消息类型
  final MessageType type;

  /// 消息负载
  final MessagePayload? payload;

  /// 附件列表
  final List<Attachment> attachments;

  /// 扩展字段
  final Map<String, dynamic> extra;

  /// 服务器消息ID
  final String messageId;

  /// 发送者用户ID
  final int senderId;

  /// 发送者昵称
  final String senderName;

  /// 发送者头像
  final String senderAvatar;

  /// 消息状态
  final MessageState state;

  /// 投递状态
  final DeliveryStatus status;

  /// 时间戳（毫秒）
  final int timestamp;

  /// 消息序号（用于排序和去重）
  final int seq;

  const RoomMessage({
    required this.roomId,
    this.clientMsgId,
    this.targetId,
    required this.type,
    this.payload,
    this.attachments = const [],
    this.extra = const {},
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.state,
    required this.status,
    required this.timestamp,
    required this.seq,
  });

  /// 从 JSON 构造 [RoomMessage] 实例
  factory RoomMessage.fromJson(Map<String, dynamic> json) {
    return RoomMessage(
      roomId: json['roomId'].toString(),
      clientMsgId: json['clientMsgId']?.toString(),
      targetId: json['targetId'] != null
          ? int.tryParse(json['targetId'].toString())
          : null,
      type: MessageType.fromCode(json['type']),
      payload: json['payload'] != null
          ? MessagePayload.fromJson(json['payload'])
          : null,
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((e) => Attachment.fromJson(e))
              .toList() ??
              const [],
      extra: (json['extra'] as Map<String, dynamic>?) ?? const {},
      messageId: json['messageId'].toString(),
      senderId: json['senderId'] != null
          ? int.parse(json['senderId'].toString())
          : 0,
      senderName: json['senderName']?.toString() ?? '',
      senderAvatar: json['senderAvatar']?.toString() ?? '',
      state: MessageState.from(json['state']),
      status: DeliveryStatus.from(json['status']),
      timestamp: json['timestamp'] != null
          ? int.parse(json['timestamp'].toString())
          : 0,
      seq: json['seq'] != null ? int.parse(json['seq'].toString()) : 0,
    );
  }

  /// 序列化为 JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'clientMsgId': clientMsgId,
      'targetId': targetId,
      'type': type.code,
      'payload': payload?.toJson(),
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'extra': extra,
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'state': state.toJson(),
      'status': status.toJson(),
      'timestamp': timestamp,
      'seq': seq,
    };
  }

  /// 创建变体副本
  RoomMessage copyWith({
    String? roomId,
    String? clientMsgId,
    int? targetId,
    MessageType? type,
    MessagePayload? payload,
    List<Attachment>? attachments,
    Map<String, dynamic>? extra,
    String? messageId,
    int? senderId,
    String? senderName,
    String? senderAvatar,
    MessageState? state,
    DeliveryStatus? status,
    int? timestamp,
    int? seq,
  }) {
    return RoomMessage(
      roomId: roomId ?? this.roomId,
      clientMsgId: clientMsgId ?? this.clientMsgId,
      targetId: targetId ?? this.targetId,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      attachments: attachments ?? this.attachments,
      extra: extra ?? this.extra,
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      state: state ?? this.state,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      seq: seq ?? this.seq,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomMessage &&
        other.roomId == roomId &&
        other.clientMsgId == clientMsgId &&
        other.targetId == targetId &&
        other.type == type &&
        other.payload == payload &&
        listEquals(other.attachments, attachments) &&
        mapEquals(other.extra, extra) &&
        other.messageId == messageId &&
        other.senderId == senderId &&
        other.senderName == senderName &&
        other.senderAvatar == senderAvatar &&
        other.state == state &&
        other.status == status &&
        other.timestamp == timestamp &&
        other.seq == seq;
  }

  @override
  int get hashCode {
    return roomId.hashCode ^
        clientMsgId.hashCode ^
        targetId.hashCode ^
        type.hashCode ^
        payload.hashCode ^
        attachments.hashCode ^
        extra.hashCode ^
        messageId.hashCode ^
        senderId.hashCode ^
        senderName.hashCode ^
        senderAvatar.hashCode ^
        state.hashCode ^
        status.hashCode ^
        timestamp.hashCode ^
        seq.hashCode;
  }
}

import '../IPacket.dart';
import 'Attachment.dart';
import 'MessageEunm.dart';
import 'MessagePayload.dart';
import 'package:flutter/foundation.dart';

/// 聊天室消息（V5 协议对齐）
///
/// 字段与服务端 RoomMessageProtoV5 保持一致。
/// V5 协议移除了 senderName/senderAvatar/targetId/state/status——
/// 这些属于业务/展示层，不在协议层传输。
@immutable
class RoomMessage implements IPacket {
  final String messageId;
  final String? clientMsgId;
  final String roomId;
  final int senderId;
  final MessageType messageType;
  final MessagePayload? payload;
  final List<Attachment> attachments;
  final Map<String, String> properties;
  final int? seq;
  final int? serverTimestamp;
  final int? clientTimestamp;

  const RoomMessage({
    required this.messageId,
    this.clientMsgId,
    required this.roomId,
    required this.senderId,
    required this.messageType,
    this.payload,
    this.attachments = const [],
    this.properties = const {},
    this.seq,
    this.serverTimestamp,
    this.clientTimestamp,
  });

  /// 兼容旧代码的别名 getter
  MessageType get type => messageType;

  /// 消息时间戳（优先取服务端时间）
  int get timestamp => serverTimestamp ?? clientTimestamp ?? 0;

  /// 向后兼容：extra 字段（从 properties 中读取）
  Map<String, dynamic> get extra => properties.cast<String, dynamic>();

  @override
  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'clientMsgId': clientMsgId,
    'roomId': roomId,
    'senderId': senderId,
    'messageType': MessageType.toCode(messageType),
    'payload': payload?.toJson(),
    'attachments': attachments.map((e) => e.toJson()).toList(),
    'properties': properties,
    'seq': seq,
    'serverTimestamp': serverTimestamp,
    'clientTimestamp': clientTimestamp,
  };

  RoomMessage copyWith({
    String? messageId,
    String? clientMsgId,
    String? roomId,
    int? senderId,
    MessageType? messageType,
    MessagePayload? payload,
    List<Attachment>? attachments,
    Map<String, String>? properties,
    int? seq,
    int? serverTimestamp,
    int? clientTimestamp,
  }) => RoomMessage(
    messageId: messageId ?? this.messageId,
    clientMsgId: clientMsgId ?? this.clientMsgId,
    roomId: roomId ?? this.roomId,
    senderId: senderId ?? this.senderId,
    messageType: messageType ?? this.messageType,
    payload: payload ?? this.payload,
    attachments: attachments ?? this.attachments,
    properties: properties ?? this.properties,
    seq: seq ?? this.seq,
    serverTimestamp: serverTimestamp ?? this.serverTimestamp,
    clientTimestamp: clientTimestamp ?? this.clientTimestamp,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomMessage &&
        other.messageId == messageId &&
        other.clientMsgId == clientMsgId &&
        other.roomId == roomId &&
        other.senderId == senderId &&
        other.messageType == messageType &&
        other.seq == seq &&
        other.serverTimestamp == serverTimestamp;
  }

  @override
  int get hashCode =>
      messageId.hashCode ^
      clientMsgId.hashCode ^
      roomId.hashCode ^
      senderId.hashCode ^
      messageType.hashCode ^
      seq.hashCode;
}

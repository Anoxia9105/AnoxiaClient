import '../IPacket.dart';
import 'Attachment.dart';
import 'MessageEunm.dart';
import 'MessagePayload.dart';
import 'package:flutter/foundation.dart';

@immutable
class RoomMessage implements IPacket {
  // Room 信息
  final String roomId;
  final String? clientMsgId;
  final int? targetId;
  final MessageType type;
  final MessagePayload? payload;
  final List<Attachment> attachments;
  final Map<String, dynamic> extra;

  // RoomMessageData 字段
  final String messageId;
  final int senderId;
  final MessageState state;
  final DeliveryStatus status;
  final int timestamp;
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
    required this.state,
    required this.status,
    required this.timestamp,
    required this.seq,
  });

  /// JSON -> RoomMessage
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
      state: MessageState.from(json['state']),
      status: DeliveryStatus.from(json['status']),
      timestamp: json['timestamp'] != null
          ? int.parse(json['timestamp'].toString())
          : 0,
      seq: json['seq'] != null ? int.parse(json['seq'].toString()) : 0,
    );
  }

  /// RoomMessage -> JSON
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
      'state': state.toJson(),
      'status': status.toJson(),
      'timestamp': timestamp,
      'seq': seq,
    };
  }

  /// 拷贝更新（不可变对象修改字段用）
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
        state.hashCode ^
        status.hashCode ^
        timestamp.hashCode ^
        seq.hashCode;
  }
}

import '../IPacket.dart';
import 'Attachment.dart';
import 'MessageEunm.dart';
import 'MessagePayload.dart';
import 'RoomMessageData.dart';

class RoomMessage extends RoomMessageData implements IPacket {
  final String? roomId;
  final int? targetId;
  final MessageType? type;
  final MessagePayload? payload;
  final List<Attachment> attachments;
  final Map<String, dynamic> extra;

  RoomMessage({
    String? messageId,
    int? senderId,
    MessageState? state,
    DeliveryStatus? status,
    int? timestamp,
    this.roomId,
    this.targetId,
    this.type,
    this.payload,
    this.attachments = const [],
    this.extra = const {},
  }) : super(
    messageId: messageId,
    senderId: senderId,
    state: state,
    status: status,
    timestamp: timestamp,
  );

  factory RoomMessage.fromJson(Map<String, dynamic> json) {
    return RoomMessage(
      // 父类字段
      messageId: json['messageId'],
      senderId: json['senderId'],
      state: json['state'] != null ? MessageState.values[json['state']] : null,
      status: json['status'] != null ? DeliveryStatus.values[json['status']] : null,
      timestamp: json['timestamp'],
      // 子类字段
      roomId: json['roomId'],
      targetId: json['targetId'],
      type: json['type'] != null ? MessageType.fromCode(json['type']) : null,
      payload: json['payload'] != null ? MessagePayload.fromJson(json['payload']) : null,
      attachments: (json['attachments'] as List?)?.map((e) => Attachment.fromJson(e)).toList() ?? [],
      extra: json['extra'] ?? {},
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'senderId': senderId,
    'state': state?.index,
    'status': status?.index,
    'timestamp': timestamp,
    'roomId': roomId,
    'targetId': targetId,
    'type': type?.code, // 注意：MessageType 序列化为 code
    'payload': payload?.toJson(),
    'attachments': attachments.map((e) => e.toJson()).toList(),
    'extra': extra,
  };

  @override
  String toString() {
    return 'RoomMessage{roomId: $roomId, targetId: $targetId, type: $type, payload: $payload, attachments: $attachments, extra: $extra}';
  }
}
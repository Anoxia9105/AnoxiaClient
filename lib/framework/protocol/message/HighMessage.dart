import '../IPacket.dart';

/// 高优消息指令类型枚举
enum HighMessageType {
  TYPING_STATUS,
  CALL_INVITE,
  CALL_CANCEL,
  CALL_ACCEPT,
  CALL_REJECT,
  CALL_END,
  CALL_BUSY,
  CALL_CANDIDATE,
  CALL_MEDIA_CHANGE,
  SYSTEM_KICK,
  MSG_REVOKE,
}

/// 高度优先消息实体
class HighMessage implements IPacket {
  final String? messageId;
  final String? roomId;
  final int? senderId;
  final String? senderDeviceId;
  final int? targetId;
  final HighMessageType? type;
  final String? content;
  final int? timestamp;

  HighMessage({
    this.messageId,
    this.roomId,
    this.senderId,
    this.senderDeviceId,
    this.targetId,
    this.type,
    this.content,
    this.timestamp,
  });

  factory HighMessage.fromJson(Map<String, dynamic> json) {
    return HighMessage(
      messageId: json['messageId'],
      roomId: json['roomId'],
      senderId: json['senderId'],
      senderDeviceId: json['senderDeviceId'],
      targetId: json['targetId'],
      type: HighMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => HighMessageType.TYPING_STATUS,
      ),
      content: json['content'],
      timestamp: json['timestamp'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'roomId': roomId,
    'senderId': senderId,
    'senderDeviceId': senderDeviceId,
    'targetId': targetId,
    'type': type!.name,
    'content': content,
    'timestamp': timestamp,
  };
}

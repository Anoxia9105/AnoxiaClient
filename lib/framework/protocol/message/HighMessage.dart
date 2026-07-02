import '../IPacket.dart';

/// 高优先级消息类型枚举（V5 协议对齐）
///
/// 数字码与服务端 HighMessageType.getCode() 保持一致。
enum HighMessageType {
  typingStatus(1),
  callInvite(7),
  callCancel(8),
  callAccept(9),
  callReject(10),
  callEnd(11),
  callBusy(12),
  callCandidate(13),
  callMediaChange(14),
  systemKick(15),
  msgRevoke(16);

  final int code;
  const HighMessageType(this.code);

  static HighMessageType fromCode(int code) {
    return HighMessageType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => HighMessageType.typingStatus,
    );
  }

  // ─── 旧名称别名（保持 high_message_service.dart switch 语句编译通过）───
  static const HighMessageType TYPING_STATUS = typingStatus;
  static const HighMessageType CALL_INVITE = callInvite;
  static const HighMessageType CALL_CANCEL = callCancel;
  static const HighMessageType CALL_ACCEPT = callAccept;
  static const HighMessageType CALL_REJECT = callReject;
  static const HighMessageType CALL_END = callEnd;
  static const HighMessageType CALL_BUSY = callBusy;
  static const HighMessageType CALL_CANDIDATE = callCandidate;
  static const HighMessageType CALL_MEDIA_CHANGE = callMediaChange;
  static const HighMessageType SYSTEM_KICK = systemKick;
  static const HighMessageType MSG_REVOKE = msgRevoke;
}

/// 高优先级消息（V5）
class HighMessage implements IPacket {
  final String? messageId;
  final String? roomId;
  final int? senderId;
  final String? senderDeviceId;
  final int? targetId;
  final HighMessageType? type;
  final String? content;
  final int? timestamp;

  const HighMessage({
    this.messageId,
    this.roomId,
    this.senderId,
    this.senderDeviceId,
    this.targetId,
    this.type,
    this.content,
    this.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'roomId': roomId,
    'senderId': senderId,
    'senderDeviceId': senderDeviceId,
    'targetId': targetId,
    'type': type?.name,
    'content': content,
    'timestamp': timestamp,
  };
}

import '../IPacket.dart';

/// 高优先级消息类型枚举
///
/// 这类消息对实时性要求高，通过独立的 WebSocket 通道传输。
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

/// 高优先级消息
///
/// 用于输入状态、通话信令等实时性要求高的消息。
/// 与普通消息的区别：走独立的高优先级通道，不经过消息队列。
class HighMessage implements IPacket {
  /// 客户端生成的消息ID
  final String? messageId;

  /// 所属聊天室ID
  final String? roomId;

  /// 发送者用户ID
  final int? senderId;

  /// 发送者设备ID（用于多设备同步）
  final String? senderDeviceId;

  /// 目标用户ID（单聊时使用）
  final int? targetId;

  /// 消息类型
  final HighMessageType? type;

  /// 消息内容（如通话邀请的 roomId）
  final String? content;

  /// 时间戳（毫秒）
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

  /// 从 JSON 构造 [HighMessage] 实例
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

  /// 序列化为 JSON
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

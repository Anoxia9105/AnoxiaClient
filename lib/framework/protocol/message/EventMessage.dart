import '../IPacket.dart';

/// 系统事件类型枚举（V5 协议对齐）
///
/// fromCode() 实现与服务端 CodecSupport.toEventType() 映射完全一致。
enum SystemEventType {
  userJoined(1),
  userLeft(2),
  userKicked(3),
  roomCreatedGroup(4), // GROUP_CREATED
  roomUpdated(5), // GROUP_NAME_CHANGED / GROUP_ANNOUNCEMENT / ROOM_UPDATED
  userRoleChanged(7), // ADMIN_CHANGED
  roomMuted(8), // USER_BANNED / USER_UNBANNED / ROOM_MUTED
  messageRecall(10),
  callStarted(12),
  callEnded(13),
  contactUpdated(14),
  contactRequest(15),
  // 仍在 V5 中传输的旧事件（高码段，避免与新码冲突）
  userOnline(16),
  userOffline(17),
  roomCreated(18),
  roomDissolved(19);

  final int code;
  const SystemEventType(this.code);

  /// 从 V5 event_type 数字码解析枚举（与服务端 CodecSupport.toEventType 对齐）
  static SystemEventType fromCode(int code) {
    return switch (code) {
      1 => SystemEventType.userJoined,
      2 => SystemEventType.userLeft,
      3 => SystemEventType.userKicked,
      4 => SystemEventType.roomCreatedGroup, // GROUP_CREATED
      5 || 6 || 20 => SystemEventType.roomUpdated, // GROUP_NAME_CHANGED / ANNOUNCEMENT / ROOM_UPDATED
      7 || 22 => SystemEventType.userRoleChanged, // ADMIN_CHANGED / USER_ROLE_CHANGED
      8 || 9 || 21 => SystemEventType.roomMuted, // USER_BANNED / UNBANNED / ROOM_MUTED
      10 || 11 => SystemEventType.messageRecall, // MESSAGE_RECALL / MESSAGE_EDIT
      12 => SystemEventType.callStarted,
      13 => SystemEventType.callEnded,
      14 => SystemEventType.contactUpdated,
      15 => SystemEventType.contactRequest,
      16 => SystemEventType.userOnline,
      17 => SystemEventType.userOffline,
      18 => SystemEventType.roomCreated,
      19 => SystemEventType.roomDissolved,
      _ => SystemEventType.contactRequest, // default fallback
    };
  }
}

/// 系统事件消息（V5）
class EventMessage implements IPacket {
  final SystemEventType eventType;
  final int operatorId;
  final String? content;
  final int timestamp;
  final Map<String, dynamic>? extra;

  const EventMessage({
    required this.eventType,
    required this.operatorId,
    this.content,
    required this.timestamp,
    this.extra,
  });

  @override
  Map<String, dynamic> toJson() => {
    'eventType': eventType.name,
    'operatorId': operatorId,
    'content': content,
    'timestamp': timestamp,
    'extra': extra,
  };
}

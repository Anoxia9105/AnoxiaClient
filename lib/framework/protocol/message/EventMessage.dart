import '../IPacket.dart';





//  USER_ONLINE(0, "用户上线", false),
//     USER_OFFLINE(1, "用户下线", false),
//     USER_JOINED(2, "用户加入聊天室", true),
//     USER_LEFT(3, "用户离开聊天室", true),
//     ROOM_CREATED(4, "创建房间", true),
//     ROOM_CREATED_GROUP(5, "创建房间-群聊", true),
//     ROOM_CLOSED(6, "房间注销", true),
//     ROOM_UPDATED(7, "房间信息更新", true),
//     ROOM_MUTED(8, "房间禁言", true),
//     USER_KICKED(9, "用户被踢出", true),
//     USER_ROLE_CHANGED(10, "用户权限变更", true);

/// 系统事件类型枚举 (对应 Java 的 SystemEventType)
enum SystemEventType {
  userOnline(0),
  userOffline(1),
  userJoined(2),
  userLeft(3),
  roomCreated(4),
  roomCreatedGroup(5),
  roomClosed(6),
  roomUpdated(7),
  userMuted(8),
  userKicked(9),
  userRoleChanged(10),
  messageRecall(11);

  final int code;
  const SystemEventType(this.code);

  // 根据 code 反序列化枚举
  static SystemEventType fromCode(int code) {
    return SystemEventType.values.firstWhere(
          (e) => e.code == code,
      orElse: () => SystemEventType.userOnline, // 默认值
    );
  }
}


class EventMessage implements IPacket{
  final SystemEventType eventType;
  final int operatorId; // Flutter 中建议用 String 处理 Long 以防溢出，或使用 int
  final String? content;
  final int timestamp;
  final Map<String, dynamic>? extra; // 新增：额外字段

  EventMessage({
    required this.eventType,
    required this.operatorId,
    this.content,
    required this.timestamp,
    this.extra, // 新增：初始化 extra
  });

  /// 从 Map (JSON) 构造对象
  factory EventMessage.fromJson(Map<String, dynamic> json) {
    return EventMessage(
      // 这里假设后端传的是枚举名字符串或者是 code
      // 如果传的是 code: SystemEventType.fromCode(json['eventType'])
      eventType: _parseEventType(json['eventType']),
      operatorId: json['operatorId'],
      content: json['content'],
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      extra: json['extra'], // 新增：解析 extra
    );
  }

  /// 转为 Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'eventType': eventType.name, // 或者用 eventType.code
      'operatorId': operatorId,
      'content': content,
      'timestamp': timestamp,
      'extra': extra, // 新增：序列化 extra
    };
  }

  static SystemEventType _parseEventType(dynamic value) {
    if (value is int) return SystemEventType.fromCode(value);
    return SystemEventType.values.firstWhere(
          (e) => e.name == value,
      orElse: () => SystemEventType.userOnline,
    );
  }
}
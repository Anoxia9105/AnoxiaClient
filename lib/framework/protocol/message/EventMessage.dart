import '../IPacket.dart';




/// 系统事件类型枚举 (对应 Java 的 SystemEventType)
enum SystemEventType {
  userOnline(0),
  userOffline(1),
  userJoined(2),
  userLeft(3),
  roomCreated(4),
  roomClosed(5),
  roomUpdated(6),
  userMuted(7),
  userKicked(8),
  userRoleChanged(9);

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

  EventMessage({
    required this.eventType,
    required this.operatorId,
    this.content,
    required this.timestamp,
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
    );
  }

  /// 转为 Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'eventType': eventType.name, // 或者用 eventType.code
      'operatorId': operatorId,
      'content': content,
      'timestamp': timestamp,
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
import '../IPacket.dart';

/// 系统事件类型枚举
///
/// 对应后端 Java SystemEventType 枚举，
/// 包含用户状态变更、房间状态变更、通话状态等事件。
enum SystemEventType {
  userOnline(0),
  userOffline(1),
  userJoined(2),
  userLeft(3),
  roomCreated(4),
  roomCreatedGroup(5),
  roomDissolved(6),
  roomUpdated(7),
  roomMuted(8),
  userKicked(9),
  userRoleChanged(10),
  messageRecall(11),
  callStarted(12),
  callEnded(13),
  contactUpdated(14),
  contactRequest(15);

  /// 事件对应的数字编码
  final int code;

  const SystemEventType(this.code);

  /// 从数字编码反序列化枚举
  static SystemEventType fromCode(int code) {
    return SystemEventType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => SystemEventType.userOnline,
    );
  }
}

/// 系统事件消息
///
/// 通过 WebSocket 推送，用于通知客户端各类系统事件。
class EventMessage implements IPacket {
  /// 事件类型
  final SystemEventType eventType;

  /// 操作者用户ID
  final int operatorId;

  /// 事件内容（JSON 字符串或纯文本）
  final String? content;

  /// 事件发生时间戳（毫秒）
  final int timestamp;

  /// 扩展字段（用于传递事件相关的额外数据）
  final Map<String, dynamic>? extra;

  EventMessage({
    required this.eventType,
    required this.operatorId,
    this.content,
    required this.timestamp,
    this.extra,
  });

  /// 从 JSON 构造 [EventMessage] 实例
  ///
  /// 自动兼容后端传来的数字编码或字符串名称
  factory EventMessage.fromJson(Map<String, dynamic> json) {
    return EventMessage(
      eventType: _parseEventType(json['eventType']),
      operatorId: int.tryParse(json['operatorId']?.toString() ?? '') ?? 0,
      content: json['content'],
      timestamp:
          int.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now().millisecondsSinceEpoch,
      extra: (json['extra'] as Map?)?.cast<String, dynamic>(),
    );
  }

  /// 序列化为 JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'eventType': eventType.name,
      'operatorId': operatorId,
      'content': content,
      'timestamp': timestamp,
      'extra': extra,
    };
  }

  /// 解析事件类型
  ///
  /// 支持数字编码、字符串名称，以及历史别名（如 roomClosed -> roomDissolved）
  static SystemEventType _parseEventType(dynamic value) {
    if (value is int) return SystemEventType.fromCode(value);
    if (value is String) {
      final normalized = value.toLowerCase().replaceAll('_', '');

      // 兼容后端历史别名
      if (normalized == 'roomclosed' || normalized == 'roomdissolved') {
        return SystemEventType.roomDissolved;
      }
      if (normalized == 'usermuted' || normalized == 'roommuted') {
        return SystemEventType.roomMuted;
      }

      for (final e in SystemEventType.values) {
        final en = e.name.toLowerCase().replaceAll('_', '');
        if (en == normalized) return e;
      }
    }
    return SystemEventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SystemEventType.userOnline,
    );
  }
}

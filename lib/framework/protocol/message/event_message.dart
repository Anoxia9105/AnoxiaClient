import '../i_packet.dart';

/// 系统事件类型枚举（V6 协议）。
///
/// 该枚举定义了服务端可能推送的所有系统事件类型，例如用户进出房间、权限变更、消息撤回等。
/// `fromCode()` 将服务端下发的数字事件码映射为对应的枚举值。
enum SystemEventType {
  roomCreated(1),
  roomDissolved(2),
  userJoined(3),
  userLeft(4),
  userKicked(5),
  roomMuted(6),
  userOnline(7),
  userOffline(8),
  roomCreatedGroup(9),
  roomUpdated(10),
  userRoleChanged(11),
  messageRecall(12),
  callStarted(13),
  callEnded(14),
  callRejected(15),
  contactUpdated(16),
  contactRequest(17),
  groupJoinRequest(18),
  groupJoinRequestHandled(19),
  profileUpdated(20),
  sessionKicked(21);

  /// 对应的 V6 `SystemEventType` 数字码。
  final int code;

  const SystemEventType(this.code);

  static SystemEventType fromCode(int code) {
    return SystemEventType.values.firstWhere(
      (event) => event.code == code,
      orElse: () => SystemEventType.contactRequest,
    );
  }
}

/// 系统事件消息（V6 协议）。
///
/// 表示服务端推送的系统事件，例如成员进出、权限变更、群组信息更新等。
/// 该类实现了 [IPacket] 接口，可用于序列化/反序列化以及与网络层交互。
/// 所有字段均为不可变（immutable），保证线程安全和状态可预测性。
class EventMessage implements IPacket {
  // ==================== 字段 ====================

  /// 系统事件类型
  final SystemEventType eventType;

  /// 操作触发者的用户 ID（例如执行踢人、禁言操作的管理员 ID）
  final int operatorId;

  /// 事件附带的内容信息（例如用户昵称、被踢原因等），可选
  final String? content;

  /// 事件发生的时间戳（毫秒，通常由服务端生成）
  final int timestamp;

  /// 扩展数据，可包含额外结构化的信息（例如被操作的用户 ID、角色类型等），可选
  final Map<String, dynamic>? extra;

  // ==================== 构造函数 ====================

  /// 构造 [EventMessage] 实例。
  ///
  /// [eventType] 和 [operatorId] 为必填，其余参数可选。
  const EventMessage({
    required this.eventType,
    required this.operatorId,
    this.content,
    required this.timestamp,
    this.extra,
  });

  // ==================== 序列化 ====================

  /// 将事件消息转换为 JSON Map，便于网络传输或持久化。
  @override
  Map<String, dynamic> toJson() => {
    'eventType': eventType.name,
    'operatorId': operatorId,
    'content': content,
    'timestamp': timestamp,
    'extra': extra,
  };

  // ==================== 字符串表示 ====================

  /// 返回事件消息的字符串表示，便于调试和日志输出。
  /// 包含所有关键字段，扩展数据 (extra) 仅输出其类型以保持简洁。
  @override
  String toString() {
    return 'EventMessage{'
        'eventType: ${eventType.name}(${eventType.code}), '
        'operatorId: $operatorId, '
        'content: $content, '
        'timestamp: $timestamp, '
        'extra: ${extra?.runtimeType ?? 'null'}'
        '}';
  }
}

import '../IPacket.dart';

/// 系统事件类型枚举（V5 协议对齐）
///
/// 该枚举定义了服务端可能推送的所有系统事件类型，例如用户进出房间、权限变更、消息撤回等。
/// `fromCode()` 方法实现了与 V5 服务端 `CodecSupport.toEventType()` 完全一致的映射，
/// 确保客户端能正确解析服务端下发的数字事件码。
enum SystemEventType {
  /// 用户加入聊天室（event_type = 1）
  userJoined(1),

  /// 用户离开聊天室（event_type = 2）
  userLeft(2),

  /// 用户被踢出聊天室（event_type = 3）
  userKicked(3),

  /// 群组被创建（event_type = 4，对应服务端 GROUP_CREATED）
  roomCreatedGroup(4),

  /// 群组信息更新，如名称、公告等（event_type = 5 / 6 / 20）
  roomUpdated(5),

  /// 用户角色变更，如设为管理员或取消管理员（event_type = 7 / 22）
  userRoleChanged(7),

  /// 聊天室被禁言或用户被禁言/解禁（event_type = 8 / 9 / 21）
  roomMuted(8),

  /// 消息被撤回或编辑（event_type = 10 / 11）
  messageRecall(10),

  /// 通话开始（event_type = 12）
  callStarted(12),

  /// 通话结束（event_type = 13）
  callEnded(13),

  /// 联系人信息更新（event_type = 14）
  contactUpdated(14),

  /// 好友请求（event_type = 15）
  contactRequest(15),

  // 以下为仍在 V5 中传输的旧事件，使用高码段以避免与新码冲突

  /// 用户上线（event_type = 16）
  userOnline(16),

  /// 用户离线（event_type = 17）
  userOffline(17),

  /// 聊天室创建（event_type = 18）
  roomCreated(18),

  /// 聊天室解散（event_type = 19）
  roomDissolved(19);

  /// 对应的 V5 协议数字事件码
  final int code;

  const SystemEventType(this.code);

  /// 从 V5 `event_type` 数字码解析为对应的枚举值。
  ///
  /// 该映射严格按照服务端 `CodecSupport.toEventType()` 的实现，
  /// 确保客户端与服务端事件类型一致。
  ///
  /// 若传入未知数字码，默认回退为 [contactRequest] 以避免空值异常。
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
      _ => SystemEventType.contactRequest, // 默认回退
    };
  }
}

/// 系统事件消息（V5 协议）
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
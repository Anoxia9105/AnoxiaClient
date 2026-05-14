/// WebSocket 消息主题枚举
///
/// 用于区分不同类型的业务消息，支持数字下标和字符串名称两种序列化方式。
///
/// 枚举值对应后端 Java 枚举：
/// - [message]：普通聊天消息
/// - [highFrequency]：高频消息（如输入状态、通话信令）
/// - [event]：系统事件消息
/// - [unknown]：未知类型（解析失败时的默认值）
enum PacketType {
  message,
  highFrequency,
  event,
  unknown;

  /// 从动态值解析枚举
  ///
  /// 支持后端传来的数字下标（0, 1, 2...）或字符串名称（"MESSAGE", "EVENT"）
  static PacketType from(dynamic value) {
    if (value == null) return PacketType.unknown;

    // 解析数字下标
    if (value is int) {
      if (value >= 0 && value < PacketType.values.length) {
        return PacketType.values[value];
      }
      return PacketType.unknown;
    }

    // 解析字符串名称
    if (value is String) {
      final normalized = value.toLowerCase().replaceAll('_', '');
      return PacketType.values.firstWhere(
        (e) => e.name.toLowerCase() == normalized,
        orElse: () => PacketType.unknown,
      );
    }

    return PacketType.unknown;
  }

  /// 序列化时的处理
  ///
  /// 传给后端数字：packet.index
  /// 传给后端字符串：packet.name.toUpperCase()
  dynamic toJson() => index;
}

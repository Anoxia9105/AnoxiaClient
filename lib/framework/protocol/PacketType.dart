/// MESSAGE_DATA，MESSAGE_STATUS 入栈枚举类型
enum PacketType {
  message,      // index: 0
  highFrequency, // index: 1
  event,        // index: 2
  unknown;      // index: 3

  /// 兼容 Java 下标序列化和字符串名称的解析
  static PacketType from(dynamic value) {
    if (value == null) return PacketType.unknown;

    // 1. 如果后端传的是数字下标 (0, 1, 2...)
    if (value is int) {
      if (value >= 0 && value < PacketType.values.length) {
        return PacketType.values[value];
      }
      return PacketType.unknown;
    }

    // 2. 如果后端传的是字符串名称 ("EVENT", "MESSAGE")
    if (value is String) {
      final normalized = value.toLowerCase().replaceAll('_', '');
      return PacketType.values.firstWhere(
            (e) => e.name.toLowerCase() == normalized,
        orElse: () => PacketType.unknown,
      );
    }

    return PacketType.unknown;
  }

  /// 序列化回 JSON 时的处理
  /// 如果你想传给后端数字：packet.index
  /// 如果你想传给后端字符串：packet.name.toUpperCase()
  dynamic toJson() => index;
}
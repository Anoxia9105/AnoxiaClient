/// WebSocket 消息主题枚举（V5 协议对齐）
///
/// 数字码与服务端 CodecConstants.TOPIC_* 保持一致：
/// - [message]：普通聊天消息（TOPIC_MESSAGE = 1）
/// - [highFrequency]：高频信令（TOPIC_HIGH_FREQUENCY = 2）
/// - [event]：系统事件（TOPIC_EVENT = 3）
/// - [ack]：发送结果 ACK（TOPIC_ACK = 4）
/// - [unknown]：未知类型
enum PacketType {
  unknown(0),
  message(1),
  highFrequency(2),
  event(3),
  ack(4);

  final int code;
  const PacketType(this.code);

  /// 从 V5 topic 数字码解析枚举
  static PacketType fromCode(int code) {
    return PacketType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => PacketType.unknown,
    );
  }

  /// 兼容旧调用（字符串 "MESSAGE" / 数字 1）
  static PacketType from(dynamic value) {
    if (value == null) return PacketType.unknown;
    if (value is int) return fromCode(value);
    if (value is String) {
      final upper = value.toUpperCase().replaceAll('_', '');
      const map = {
        'MESSAGE': PacketType.message,
        'HIGHFREQUENCY': PacketType.highFrequency,
        'EVENT': PacketType.event,
        'ACK': PacketType.ack,
      };
      return map[upper] ?? PacketType.unknown;
    }
    return PacketType.unknown;
  }

  dynamic toJson() => code;
}

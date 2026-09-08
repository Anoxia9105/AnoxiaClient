/// WebSocket 消息主题枚举（V6 协议）
///
/// 数字码与 V6 内部 PacketFrame 主题保持一致：
/// - [message]：普通聊天消息（1）
/// - [highFrequency]：高频信令（2）
/// - [event]：系统事件（3）
/// - [ack]：发送结果 ACK（4）
/// - [unknown]：未知类型
enum PacketType {
  unknown(0),
  message(1),
  highFrequency(2),
  event(3),
  ack(4),
  announcement(5);

  final int code;
  const PacketType(this.code);

  /// 从主题数字码解析枚举
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
        'ANNOUNCEMENT': PacketType.announcement,
      };
      return map[upper] ?? PacketType.unknown;
    }
    return PacketType.unknown;
  }

  dynamic toJson() => code;
}

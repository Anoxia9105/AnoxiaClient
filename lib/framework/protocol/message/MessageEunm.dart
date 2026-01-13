/// 消息类型
enum MessageType {
  quill(0),
  image(1),
  file(2),
  audio(3),
  video(4),
  text(5);

  final int code;
  const MessageType(this.code);

  static MessageType fromCode(int code) {
    return MessageType.values.firstWhere((e) => e.code == code, orElse: () => MessageType.text);
  }
}

/// 消息状态
enum MessageState {
  normal,
  read,
  recalled,
  edited;

  /// 从后端字符串 / 数值安全解析
  static MessageState from(dynamic value) {
    if (value == null) return MessageState.normal;

    if (value is String) {
      return MessageState.values.firstWhere(
            (e) => e.name.toUpperCase() == value.toUpperCase(),
        orElse: () => MessageState.normal,
      );
    }

    if (value is int) {
      if (value >= 0 && value < MessageState.values.length) {
        return MessageState.values[value];
      }
    }

    return MessageState.normal;
  }

  /// 序列化给后端（字符串，更稳定）
  String toJson() => name.toUpperCase();
}

/// 链路状态
enum DeliveryStatus {

  sending, sent, delivered, failed;
  static DeliveryStatus from(dynamic value) {
    if (value == null) return DeliveryStatus.sending;

    if (value is String) {
      return DeliveryStatus.values.firstWhere(
            (e) => e.name.toUpperCase() == value.toUpperCase(),
        orElse: () => DeliveryStatus.failed,
      );
    }

    if (value is int) {
      if (value >= 0 && value < DeliveryStatus.values.length) {
        return DeliveryStatus.values[value];
      }
    }

    return DeliveryStatus.failed;
  }
  /// 序列化给后端（字符串，更稳定）
  String toJson() => name.toUpperCase();
}
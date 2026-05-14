/// 消息类型枚举
///
/// 定义聊天消息的内容类型。
enum MessageType {
  quill(0),
  image(1),
  file(2),
  audio(3),
  video(4),
  text(5),
  system(6);

  /// 数字编码（与后端一致）
  final int code;

  const MessageType(this.code);

  /// 从动态值解析枚举
  ///
  /// 支持后端传来的字符串（如 "TEXT"）或数字（如 5）
  static MessageType fromCode(dynamic value) {
    if (value == null) return MessageType.text;

    if (value is String) {
      return MessageType.values.firstWhere(
        (e) => e.name.toUpperCase() == value.toUpperCase(),
        orElse: () => MessageType.text,
      );
    }

    if (value is int) {
      return MessageType.values.firstWhere(
        (e) => e.code == value,
        orElse: () => MessageType.text,
      );
    }

    return MessageType.text;
  }
}

/// 消息状态枚举
///
/// 表示消息的当前状态，影响 UI 展示。
enum MessageState {
  active,
  recalled,
  edited;

  /// 从动态值安全解析枚举
  static MessageState from(dynamic value) {
    if (value == null) return MessageState.active;

    if (value is String) {
      return MessageState.values.firstWhere(
        (e) => e.name.toUpperCase() == value.toUpperCase(),
        orElse: () => MessageState.active,
      );
    }

    if (value is int) {
      if (value >= 0 && value < MessageState.values.length) {
        return MessageState.values[value];
      }
    }

    return MessageState.active;
  }

  /// 序列化为字符串传给后端
  String toJson() => name.toUpperCase();
}

/// 消息投递状态枚举
///
/// 表示消息在客户端的发送状态，影响 UI 展示。
enum DeliveryStatus {
  sending,
  failed,
  sent;

  /// 从动态值解析枚举
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

  /// 序列化为字符串传给后端
  String toJson() => name.toUpperCase();
}

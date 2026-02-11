/// 消息类型
enum MessageType {
  quill(0),
  image(1),
  file(2),
  audio(3),
  video(4),
  text(5),
  system(6);

  final int code;
  const MessageType(this.code);

  static MessageType fromCode(int code) {
    return MessageType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => MessageType.text,
    );
  }
}

/// 消息状态
enum MessageState {
  active, // 默认：正常显示
  recalled, // 撤回：UI 需显示“对方撤回了一条消息”
  edited; // 已编辑：UI 需在内容旁标注“已编辑”

  /// 从后端字符串 / 数值安全解析
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

  /// 序列化给后端（字符串，更稳定）
  String toJson() => name.toUpperCase();
}

/// 链路状态
enum DeliveryStatus {
  sending, // 本地：发送中（转圈）
  failed, // 本地：发送失败（红感叹号）
  sent; // 成功：服务器已收到（单勾）

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

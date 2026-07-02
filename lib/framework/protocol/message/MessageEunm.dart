/// 消息类型枚举（V5 协议对齐）
///
/// 数字码与服务端 MessageType.getCode() 保持一致。
enum MessageType {
  text(1),
  richText(2), // 原 quill
  image(3),
  audio(4),
  video(5),
  file(6),
  emoji(7),
  location(8),
  card(9),
  system(10);

  final int code;
  const MessageType(this.code);

  /// 获取枚举的数字码
  static int toCode(MessageType? type) => type == null ? 0 : type.code;

  /// 从数字码或字符串名称解析枚举
  static MessageType fromCode(dynamic value) {
    if (value == null) return MessageType.text;

    if (value is int) {
      return MessageType.values.firstWhere(
        (e) => e.code == value,
        orElse: () => MessageType.text,
      );
    }

    if (value is String) {
      const nameMap = <String, MessageType>{
        'TEXT': MessageType.text,
        'RICH_TEXT': MessageType.richText,
        'RICHTEXT': MessageType.richText,
        'QUILL': MessageType.richText, // 旧名称兼容
        'IMAGE': MessageType.image,
        'AUDIO': MessageType.audio,
        'VIDEO': MessageType.video,
        'FILE': MessageType.file,
        'EMOJI': MessageType.emoji,
        'LOCATION': MessageType.location,
        'CARD': MessageType.card,
        'SYSTEM': MessageType.system,
      };
      return nameMap[value.toUpperCase()] ?? MessageType.text;
    }

    return MessageType.text;
  }
}

/// 消息本地状态枚举（客户端发送态，不在 V5 协议中传输）
enum MessageState {
  active,
  recalled,
  edited;

  static MessageState from(dynamic value) {
    if (value == null) return MessageState.active;
    if (value is String) {
      return MessageState.values.firstWhere(
        (e) => e.name.toUpperCase() == value.toUpperCase(),
        orElse: () => MessageState.active,
      );
    }
    if (value is int && value >= 0 && value < MessageState.values.length) {
      return MessageState.values[value];
    }
    return MessageState.active;
  }

  String toJson() => name.toUpperCase();
}

/// 消息投递状态枚举（客户端本地状态，不在 V5 协议中传输）
enum DeliveryStatus {
  sending,
  failed,
  sent;

  static DeliveryStatus from(dynamic value) {
    if (value == null) return DeliveryStatus.sending;
    if (value is String) {
      return DeliveryStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == value.toUpperCase(),
        orElse: () => DeliveryStatus.failed,
      );
    }
    if (value is int && value >= 0 && value < DeliveryStatus.values.length) {
      return DeliveryStatus.values[value];
    }
    return DeliveryStatus.failed;
  }

  String toJson() => name.toUpperCase();
}

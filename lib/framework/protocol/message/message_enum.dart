/// 消息类型和投递状态枚举定义。
///
/// 定义 V5 协议中的消息类型编码和本地 UI 投递状态。
/// Message type enum aligned with V5 protocol numeric codes.
enum MessageType {
  /// 文本消息。
  text(1),

  /// 富文本消息。
  richText(2),

  /// 图片消息。
  image(3),

  /// 语音消息。
  audio(4),

  /// 视频消息。
  video(5),

  /// 文件消息。
  file(6),

  /// 表情消息。
  emoji(7),

  /// 位置消息。
  location(8),

  /// 名片消息。
  card(9),

  /// 系统消息。
  system(10);

  /// 协议中的数字编码。
  final int code;
  const MessageType(this.code);

  /// 将消息类型转换为协议编码，[type] 为 `null` 时返回 0。
  static int toCode(MessageType? type) => type == null ? 0 : type.code;

  /// 从编码值解析消息类型。
  ///
  /// 支持 [int] 编码、[String] 名称，无法识别时返回 [text]。
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
        'QUILL': MessageType.richText,
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

/// Local UI delivery state. This is not part of RoomMessage V5 protocol.
enum DeliveryStatus {
  /// 发送中。
  sending,

  /// 发送失败。
  failed,

  /// 已发送。
  sent;

  /// 从任意值解析投递状态。
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

  /// 将投递状态序列化为大写字符串。
  String toJson() => name.toUpperCase();
}

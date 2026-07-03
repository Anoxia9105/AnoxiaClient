/// Message type enum aligned with V5 protocol numeric codes.
enum MessageType {
  text(1),
  richText(2),
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

  static int toCode(MessageType? type) => type == null ? 0 : type.code;

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

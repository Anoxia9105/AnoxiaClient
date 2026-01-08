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
enum MessageState { normal, read, recalled, edited }

/// 链路状态
enum DeliveryStatus { sending, sent, delivered, failed }
class AiChatMessage {
  final String content;
  final bool isAi;
  final bool streaming;

  AiChatMessage({
    required this.content,
    required this.isAi,
    this.streaming = false,
  });

  AiChatMessage copyWith({
    String? content,
    bool? streaming,
  }) {
    return AiChatMessage(
      content: content ?? this.content,
      isAi: isAi,
      streaming: streaming ?? this.streaming,
    );
  }
}

class AiChatMessage {
  final String content;
  final bool isAi;
  final bool isStreaming; // 标记 AI 是否还在蹦字

  AiChatMessage({
    required this.content,
    required this.isAi,
    this.isStreaming = false
  });

  // 用于流式更新内容
  AiChatMessage copyWith({String? content, bool? isStreaming}) {
    return AiChatMessage(
      content: content ?? this.content,
      isAi: isAi,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
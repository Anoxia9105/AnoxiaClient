/// AI 聊天消息模型
///
/// 用于表示对话中单条消息的展示状态，包括内容、来源标识和流式传输状态。
/// 与 [ChatMessage] 的区别：此模型专注于 UI 展示层面的数据，
/// 而 [ChatMessage] 是完整的业务消息实体。
class AiChatMessage {
  /// 消息文本内容
  final String content;

  /// 是否为 AI 发送的消息，true = AI 回复，false = 用户输入
  final bool isAi;

  /// 是否处于流式传输状态，仅 [isAi] 为 true 时有效
  final bool streaming;

  AiChatMessage({
    required this.content,
    required this.isAi,
    this.streaming = false,
  });

  /// 创建当前消息的副本，支持局部更新
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

/// 聊天输入状态类
///
/// 管理聊天输入框的各种状态，包括：
/// - 输入文本内容
/// - 是否正在输入
/// - 表情面板显示状态
/// - 更多功能面板显示状态
/// - 语音模式状态
/// - 是否正在录音
/// - @提及用户列表
class ChatInputState {
  /// 输入内容
  final String text;

  /// 是否正在输入
  final bool isTyping;

  /// 是否显示表情面板
  final bool showEmojiPanel;

  /// 是否显示更多功能面板
  final bool showMorePanel;

  /// 是否语音模式
  final bool voiceMode;

  /// 是否正在录音
  final bool recording;

  /// @用户列表
  final Map<String, int> mentions;

  const ChatInputState({
    this.text = '',
    this.isTyping = false,
    this.showEmojiPanel = false,
    this.showMorePanel = false,
    this.voiceMode = false,
    this.recording = false,
    this.mentions = const {},
  });

  /// copyWith
  ChatInputState copyWith({
    String? text,
    bool? isTyping,
    bool? showEmojiPanel,
    bool? showMorePanel,
    bool? voiceMode,
    bool? recording,
    Map<String, int>? mentions,
  }) {
    return ChatInputState(
      text: text ?? this.text,
      isTyping: isTyping ?? this.isTyping,
      showEmojiPanel: showEmojiPanel ?? this.showEmojiPanel,
      showMorePanel: showMorePanel ?? this.showMorePanel,
      voiceMode: voiceMode ?? this.voiceMode,
      recording: recording ?? this.recording,
      mentions: mentions ?? this.mentions,
    );
  }

  @override
  String toString() {
    return 'ChatInputState('
        'text: $text, '
        'isTyping: $isTyping, '
        'showEmojiPanel: $showEmojiPanel, '
        'showMorePanel: $showMorePanel, '
        'voiceMode: $voiceMode, '
        'recording: $recording, '
        'mentions: $mentions'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatInputState &&
        other.text == text &&
        other.isTyping == isTyping &&
        other.showEmojiPanel == showEmojiPanel &&
        other.showMorePanel == showMorePanel &&
        other.voiceMode == voiceMode &&
        other.recording == recording &&
        other.mentions == mentions;
  }

  @override
  int get hashCode {
    return Object.hash(
      text,
      isTyping,
      showEmojiPanel,
      showMorePanel,
      voiceMode,
      recording,
      mentions,
    );
  }
}
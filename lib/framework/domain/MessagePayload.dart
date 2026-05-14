/// 消息负载模型
///
/// 用于承载消息的扩展信息，支持富文本、引用回复、@提及等功能。
/// 与纯文本 [ChatMessage.content] 的区别：此模型支持结构化的多媒体内容。
class MessagePayload {
  /// 文本内容（纯文本或 Markdown）
  final String? content;

  /// Quill 富文本 Delta 格式的 JSON 字符串
  final String? quillDelta;

  /// 被回复消息的 ID（用于引用功能）
  final String? replyTo;

  /// @ 提及的用户 ID 列表
  final List<int>? mentions;

  /// Markdown 格式的内容
  final String? markdown;

  /// emoji 统一码（用于 emoji  реакции）
  final String? emojiCode;

  const MessagePayload({
    this.content,
    this.quillDelta,
    this.replyTo,
    this.mentions,
    this.markdown,
    this.emojiCode,
  });

  /// 从 JSON 数据构造 [MessagePayload] 实例
  factory MessagePayload.fromJson(Map<String, dynamic> json) {
    return MessagePayload(
      content: json['content'] as String?,
      quillDelta: json['quillDelta'] as String?,
      replyTo: json['replyTo'] as String?,
      mentions: (json['mentions'] as List?)
          ?.map((e) => e as int)
          .toList(),
      markdown: json['markdown'] as String?,
      emojiCode: json['emojiCode'] as String?,
    );
  }

  /// 将当前实例转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'quillDelta': quillDelta,
      'replyTo': replyTo,
      'mentions': mentions,
      'markdown': markdown,
      'emojiCode': emojiCode,
    };
  }

  /// 创建当前实例的变体副本
  MessagePayload copyWith({
    String? content,
    String? quillDelta,
    String? replyTo,
    List<int>? mentions,
    String? markdown,
    String? emojiCode,
  }) {
    return MessagePayload(
      content: content ?? this.content,
      quillDelta: quillDelta ?? this.quillDelta,
      replyTo: replyTo ?? this.replyTo,
      mentions: mentions ?? this.mentions,
      markdown: markdown ?? this.markdown,
      emojiCode: emojiCode ?? this.emojiCode,
    );
  }

  @override
  String toString() {
    return 'MessagePayload('
        'content: $content, '
        'quillDelta: $quillDelta, '
        'replyTo: $replyTo, '
        'mentions: $mentions, '
        'markdown: $markdown, '
        'emojiCode: $emojiCode'
        ')';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MessagePayload &&
            runtimeType == other.runtimeType &&
            content == other.content &&
            quillDelta == other.quillDelta &&
            replyTo == other.replyTo &&
            _listEquals(mentions, other.mentions) &&
            markdown == other.markdown &&
            emojiCode == other.emojiCode;
  }

  @override
  int get hashCode =>
      Object.hash(content, quillDelta, replyTo, mentions, markdown, emojiCode);

  /// 比较两个列表是否相等
  static bool _listEquals(List<int>? a, List<int>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

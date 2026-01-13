class MessagePayload {
  /// 文本内容
  final String? content;

  /// Quill 富文本 Delta
  final String? quillDelta;

  /// 引用的消息 ID
  final String? replyTo;

  /// @ 的用户 ID 列表
  final List<int>? mentions;

  /// Markdown 内容
  final String? markdown;

  /// emoji 编码
  final String? emojiCode;

  const MessagePayload({
    this.content,
    this.quillDelta,
    this.replyTo,
    this.mentions,
    this.markdown,
    this.emojiCode,
  });

  /// JSON -> Dart
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

  /// Dart -> JSON
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

  /// 拷贝构造（状态更新用）
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

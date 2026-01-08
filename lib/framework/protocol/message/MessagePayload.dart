class MessagePayload {
  final String? content;
  final String? quillDelta;
  final String? replyTo;
  final List<int>? mentions;
  final String? markdown;
  final String? emojiCode;

  MessagePayload({this.content, this.quillDelta, this.replyTo, this.mentions, this.markdown, this.emojiCode});

  factory MessagePayload.fromJson(Map<String, dynamic> json) => MessagePayload(
    content: json['content'],
    quillDelta: json['quillDelta'],
    replyTo: json['replyTo'],
    mentions: (json['mentions'] as List?)?.map((e) => e as int).toList(),
    markdown: json['markdown'],
    emojiCode: json['emojiCode'],
  );

  Map<String, dynamic> toJson() => {
    'content': content,
    'quillDelta': quillDelta,
    'replyTo': replyTo,
    'mentions': mentions,
    'markdown': markdown,
    'emojiCode': emojiCode,
  };

  @override
  String toString() {
    return 'MessagePayload{content: $content, quillDelta: $quillDelta, replyTo: $replyTo, mentions: $mentions, markdown: $markdown, emojiCode: $emojiCode}';
  }


}
/// 协议层消息负载模型
///
/// 定义消息的扩展属性，支持富文本、引用、@提及等。
/// 与领域层的 [domain.MessagePayload] 字段一致，此处用于协议解析。
class MessagePayload {
  /// 文本内容
  final String? content;

  /// Quill 富文本 Delta JSON 字符串
  final String? quillDelta;

  /// 被回复消息的 ID
  final String? replyTo;

  /// @ 提及的用户 ID 列表
  final List<int>? mentions;

  /// Markdown 格式内容
  final String? markdown;

  /// emoji 统一码
  final String? emojiCode;

  MessagePayload({
    this.content,
    this.quillDelta,
    this.replyTo,
    this.mentions,
    this.markdown,
    this.emojiCode,
  });

  /// 从 JSON 构造 [MessagePayload] 实例
  factory MessagePayload.fromJson(Map<String, dynamic> json) => MessagePayload(
        content: json['content'],
        quillDelta: json['quillDelta'],
        replyTo: json['replyTo'],
        mentions: (json['mentions'] as List?)?.map((e) => e as int).toList(),
        markdown: json['markdown'],
        emojiCode: json['emojiCode'],
      );

  /// 序列化为 JSON
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

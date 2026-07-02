/// 协议层消息负载模型（V5 兼容）
///
/// 保持扁平结构，便于 UI 层直接读取。
/// 编解码时由 ImPacketV5 负责与 V5 Protobuf 类型互转。
class MessagePayload {
  /// 文本内容（TEXT/纯文本预览）
  final String? content;

  /// Quill 富文本 Delta JSON
  final String? quillDelta;

  /// 被回复消息的 ID
  final String? replyTo;

  /// @ 提及的用户 ID 列表
  final List<int>? mentions;

  /// Markdown 格式内容
  final String? markdown;

  /// Emoji 统一码
  final String? emojiCode;

  /// 音频时长（毫秒）
  final int? audioDuration;

  const MessagePayload({
    this.content,
    this.quillDelta,
    this.replyTo,
    this.mentions,
    this.markdown,
    this.emojiCode,
    this.audioDuration,
  });

  factory MessagePayload.fromJson(Map<String, dynamic> json) => MessagePayload(
    content: json['content'],
    quillDelta: json['quillDelta'],
    replyTo: json['replyTo'],
    mentions: (json['mentions'] as List?)?.map((e) => e as int).toList(),
    markdown: json['markdown'],
    emojiCode: json['emojiCode'],
    audioDuration: json['audioDuration'],
  );

  Map<String, dynamic> toJson() => {
    'content': content,
    'quillDelta': quillDelta,
    'replyTo': replyTo,
    'mentions': mentions,
    'markdown': markdown,
    'emojiCode': emojiCode,
    'audioDuration': audioDuration,
  };

  @override
  String toString() =>
      'MessagePayload{content: $content, quillDelta: $quillDelta, '
      'replyTo: $replyTo, mentions: $mentions, markdown: $markdown, '
      'emojiCode: $emojiCode, audioDuration: $audioDuration}';
}

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

  factory MessagePayload.fromJson(Map<String, dynamic> json) {
    final text = _asMap(json['text']);
    if (text != null) {
      final content = _readString(text, ['text', 'content']);
      final markdown = _readString(text, ['markdown']);
      final interaction = _asMap(text['interaction']);
      return MessagePayload(
        content: content.isNotEmpty ? content : markdown,
        markdown: markdown.isNotEmpty ? markdown : null,
        replyTo: _readString(interaction, [
          'replyToMessageId',
          'reply_to_message_id',
          'replyTo',
        ]),
        mentions: _readIntList(
          interaction?['mentionUserIds'] ?? interaction?['mentions'],
        ),
      );
    }

    final richText = _asMap(json['richText'] ?? json['rich_text']);
    if (richText != null) {
      final interaction = _asMap(richText['interaction']);
      return MessagePayload(
        content: _readString(richText, ['plainText', 'plain_text', 'content']),
        quillDelta: _readString(richText, [
          'deltaJson',
          'delta_json',
          'quillDelta',
          'quill_delta',
        ]),
        replyTo: _readString(interaction, [
          'replyToMessageId',
          'reply_to_message_id',
          'replyTo',
        ]),
        mentions: _readIntList(
          interaction?['mentionUserIds'] ?? interaction?['mentions'],
        ),
      );
    }

    final image = _asMap(json['image']);
    if (image != null) {
      final interaction = _asMap(image['interaction']);
      return MessagePayload(
        content: _readString(image, ['caption', 'content']),
        replyTo: _readString(interaction, [
          'replyToMessageId',
          'reply_to_message_id',
          'replyTo',
        ]),
        mentions: _readIntList(
          interaction?['mentionUserIds'] ?? interaction?['mentions'],
        ),
      );
    }

    final file = _asMap(json['file']);
    if (file != null) {
      final interaction = _asMap(file['interaction']);
      return MessagePayload(
        content: _readString(file, ['caption', 'content']),
        replyTo: _readString(interaction, [
          'replyToMessageId',
          'reply_to_message_id',
          'replyTo',
        ]),
        mentions: _readIntList(
          interaction?['mentionUserIds'] ?? interaction?['mentions'],
        ),
      );
    }

    final audio = _asMap(json['audio']);
    if (audio != null) {
      return MessagePayload(
        content: '[audio]',
        audioDuration: _readInt(audio['durationMs'] ?? audio['duration_ms']),
      );
    }

    final video = _asMap(json['video']);
    if (video != null) {
      final interaction = _asMap(video['interaction']);
      return MessagePayload(
        content: _readString(video, ['caption', 'content']).isNotEmpty
            ? _readString(video, ['caption', 'content'])
            : '[video]',
        replyTo: _readString(interaction, [
          'replyToMessageId',
          'reply_to_message_id',
          'replyTo',
        ]),
        mentions: _readIntList(
          interaction?['mentionUserIds'] ?? interaction?['mentions'],
        ),
        audioDuration: _readInt(video['durationMs'] ?? video['duration_ms']),
      );
    }

    final emoji = _asMap(json['emoji']);
    if (emoji != null) {
      final fallback = _readString(emoji, [
        'textFallback',
        'text_fallback',
        'content',
      ]);
      final emojiId = _readString(emoji, ['emojiId', 'emoji_id', 'emojiCode']);
      return MessagePayload(
        content: fallback.isNotEmpty ? fallback : emojiId,
        emojiCode: emojiId.isNotEmpty ? emojiId : fallback,
      );
    }

    final location = _asMap(json['location']);
    if (location != null) {
      final title = _readString(location, ['title']);
      final address = _readString(location, ['address']);
      return MessagePayload(content: title.isNotEmpty ? title : address);
    }

    final card = _asMap(json['card']);
    if (card != null) {
      final title = _readString(card, ['title']);
      final summary = _readString(card, ['summary']);
      return MessagePayload(content: title.isNotEmpty ? title : summary);
    }

    final system = _asMap(json['system']);
    if (system != null) {
      return MessagePayload(
        content: _readString(system, [
          'text',
          'eventCode',
          'event_code',
          'content',
        ]),
      );
    }

    return MessagePayload(
      content: _readString(json, [
        'content',
        'text',
        'caption',
        'plainText',
        'plain_text',
      ]),
      quillDelta: _readString(json, [
        'quillDelta',
        'quill_delta',
        'deltaJson',
        'delta_json',
      ]),
      replyTo: _readString(json, [
        'replyTo',
        'replyToMessageId',
        'reply_to_message_id',
      ]),
      mentions: _readIntList(json['mentions'] ?? json['mentionUserIds']),
      markdown: _readString(json, ['markdown']),
      emojiCode: _readString(json, ['emojiCode', 'emojiId', 'emoji_id']),
      audioDuration: _readInt(
        json['audioDuration'] ?? json['durationMs'] ?? json['duration_ms'],
      ),
    );
  }

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

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _readString(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return '';
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      final text = value.toString();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static int? _readInt(dynamic value) =>
      value == null ? null : int.tryParse(value.toString());

  static List<int>? _readIntList(dynamic value) {
    if (value is! List) return null;
    final result = value
        .map((e) => int.tryParse(e.toString()))
        .whereType<int>()
        .toList();
    return result.isEmpty ? null : result;
  }
}

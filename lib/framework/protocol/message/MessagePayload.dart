import 'Attachment.dart';
import 'MessageEunm.dart';

class MessagePayload {
  final String? content;
  final String? quillDelta;
  final String? replyTo;
  final List<int>? mentions;
  final String? markdown;
  final String? emojiCode;
  final int? audioDuration;
  final Attachment? image;
  final Attachment? audio;
  final Attachment? video;
  final Attachment? cover;
  final Attachment? file;
  final Attachment? asset;
  final String? waveform;

  const MessagePayload({
    this.content,
    this.quillDelta,
    this.replyTo,
    this.mentions,
    this.markdown,
    this.emojiCode,
    this.audioDuration,
    this.image,
    this.audio,
    this.video,
    this.cover,
    this.file,
    this.asset,
    this.waveform,
  });

  List<Attachment> get mediaAttachments {
    final result = <Attachment>[];
    for (final item in [image, audio, video, cover, file, asset]) {
      if (item != null && item.url?.isNotEmpty == true) result.add(item);
    }
    return result;
  }

  MessagePayload withMedia(MessageType type, List<Attachment> attachments) {
    if (attachments.isEmpty) return this;
    final first = attachments.first;
    return switch (type) {
      MessageType.image => copyWith(image: first.copyWith(kind: 'IMAGE')),
      MessageType.audio => copyWith(audio: first.copyWith(kind: 'AUDIO')),
      MessageType.video => copyWith(
        video: first.copyWith(kind: 'VIDEO'),
        cover: attachments.length > 1
            ? attachments[1].copyWith(kind: 'IMAGE')
            : cover,
      ),
      MessageType.file => copyWith(file: first.copyWith(kind: 'FILE')),
      MessageType.emoji => copyWith(asset: first.copyWith(kind: 'FILE')),
      _ => this,
    };
  }

  MessagePayload copyWith({
    String? content,
    String? quillDelta,
    String? replyTo,
    List<int>? mentions,
    String? markdown,
    String? emojiCode,
    int? audioDuration,
    Attachment? image,
    Attachment? audio,
    Attachment? video,
    Attachment? cover,
    Attachment? file,
    Attachment? asset,
    String? waveform,
  }) => MessagePayload(
    content: content ?? this.content,
    quillDelta: quillDelta ?? this.quillDelta,
    replyTo: replyTo ?? this.replyTo,
    mentions: mentions ?? this.mentions,
    markdown: markdown ?? this.markdown,
    emojiCode: emojiCode ?? this.emojiCode,
    audioDuration: audioDuration ?? this.audioDuration,
    image: image ?? this.image,
    audio: audio ?? this.audio,
    video: video ?? this.video,
    cover: cover ?? this.cover,
    file: file ?? this.file,
    asset: asset ?? this.asset,
    waveform: waveform ?? this.waveform,
  );

  factory MessagePayload.fromJson(Map<String, dynamic> json) {
    final text = _asMap(json['text']);
    if (text != null) {
      final interaction = _asMap(text['interaction']);
      final content = _readString(text, ['text', 'content']);
      final markdown = _readString(text, ['markdown']);
      return MessagePayload(
        content: content.isNotEmpty ? content : markdown,
        markdown: markdown.isNotEmpty ? markdown : null,
        replyTo: _readReplyTo(interaction),
        mentions: _readMentions(interaction),
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
        replyTo: _readReplyTo(interaction),
        mentions: _readMentions(interaction),
      );
    }

    final imagePayload = _asMap(json['image']);
    if (imagePayload != null) {
      final interaction = _asMap(imagePayload['interaction']);
      return MessagePayload(
        content: _readString(imagePayload, ['caption', 'content']),
        image: _readAttachment(imagePayload['image'])?.copyWith(kind: 'IMAGE'),
        replyTo: _readReplyTo(interaction),
        mentions: _readMentions(interaction),
      );
    }

    final filePayload = _asMap(json['file']);
    if (filePayload != null) {
      final interaction = _asMap(filePayload['interaction']);
      return MessagePayload(
        content: _readString(filePayload, ['caption', 'content']),
        file: _readAttachment(filePayload['file'])?.copyWith(kind: 'FILE'),
        replyTo: _readReplyTo(interaction),
        mentions: _readMentions(interaction),
      );
    }

    final audioPayload = _asMap(json['audio']);
    if (audioPayload != null) {
      return MessagePayload(
        content: '[audio]',
        audioDuration: _readInt(
          audioPayload['durationMs'] ?? audioPayload['duration_ms'],
        ),
        audio: _readAttachment(audioPayload['audio'])?.copyWith(kind: 'AUDIO'),
        waveform: _readString(audioPayload, ['waveform']),
      );
    }

    final videoPayload = _asMap(json['video']);
    if (videoPayload != null) {
      final interaction = _asMap(videoPayload['interaction']);
      final caption = _readString(videoPayload, ['caption', 'content']);
      return MessagePayload(
        content: caption.isNotEmpty ? caption : '[video]',
        replyTo: _readReplyTo(interaction),
        mentions: _readMentions(interaction),
        audioDuration: _readInt(
          videoPayload['durationMs'] ?? videoPayload['duration_ms'],
        ),
        video: _readAttachment(videoPayload['video'])?.copyWith(kind: 'VIDEO'),
        cover: _readAttachment(videoPayload['cover'])?.copyWith(kind: 'IMAGE'),
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
        asset: _readAttachment(emoji['asset'])?.copyWith(kind: 'FILE'),
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
      image: _readAttachment(json['image'])?.copyWith(kind: 'IMAGE'),
      audio: _readAttachment(json['audio'])?.copyWith(kind: 'AUDIO'),
      video: _readAttachment(json['video'])?.copyWith(kind: 'VIDEO'),
      cover: _readAttachment(json['cover'])?.copyWith(kind: 'IMAGE'),
      file: _readAttachment(json['file'])?.copyWith(kind: 'FILE'),
      asset: _readAttachment(json['asset'])?.copyWith(kind: 'FILE'),
      waveform: _readString(json, ['waveform']),
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
    'image': image?.toJson(),
    'audio': audio?.toJson(),
    'video': video?.toJson(),
    'cover': cover?.toJson(),
    'file': file?.toJson(),
    'asset': asset?.toJson(),
    'waveform': waveform,
  };

  @override
  String toString() =>
      'MessagePayload{content: $content, quillDelta: $quillDelta, '
      'replyTo: $replyTo, mentions: $mentions, markdown: $markdown, '
      'emojiCode: $emojiCode, audioDuration: $audioDuration, '
      'mediaAttachments: ${mediaAttachments.length}}';

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

  static String _readReplyTo(Map<String, dynamic>? interaction) => _readString(
    interaction,
    ['replyToMessageId', 'reply_to_message_id', 'replyTo'],
  );

  static List<int>? _readMentions(Map<String, dynamic>? interaction) =>
      _readIntList(interaction?['mentionUserIds'] ?? interaction?['mentions']);

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

  static Attachment? _readAttachment(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    final attachment = Attachment.fromJson(map);
    if (attachment.url?.isNotEmpty != true) return null;
    return attachment;
  }
}

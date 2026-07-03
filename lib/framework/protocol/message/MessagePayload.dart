import 'Attachment.dart';
import 'MessageEunm.dart';

/// 消息载荷（Payload），用于存储消息的富文本内容、媒体附件、引用回复、@提及等结构化数据。
///
/// 支持多种消息类型（文本、图片、音频、视频、文件、表情、位置、卡片、系统消息等），
/// 通过不同的字段组合来表示不同消息的具体内容。其中 [mediaAttachments] 可获取所有媒体附件列表。
class MessagePayload {
  /// 纯文本内容（可能为消息的简短描述或文本消息体）
  final String? content;

  /// Quill 富文本编辑器生成的 Delta 数据（JSON 字符串），用于显示带格式的文本
  final String? quillDelta;

  /// 引用回复的消息 ID（被回复的消息标识）
  final String? replyTo;

  /// 被 @ 提及的用户 ID 列表
  final List<int>? mentions;

  /// Markdown 格式的文本内容（若消息以 Markdown 形式发送）
  final String? markdown;

  /// 表情符号代码（如 `:smile:` 或 Unicode 码点）
  final String? emojiCode;

  /// 音频时长（单位：毫秒）
  final int? audioDuration;

  /// 图片附件
  final Attachment? image;

  /// 音频附件
  final Attachment? audio;

  /// 视频附件
  final Attachment? video;

  /// 视频封面图附件（通常与视频成对出现）
  final Attachment? cover;

  /// 文件附件（文档、压缩包等）
  final Attachment? file;

  /// 资源附件（如表情包、贴纸等特殊资源）
  final Attachment? asset;

  /// 音频波形数据（用于绘制语音波形图，一般为 Base64 编码的字符串）
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

  /// 获取所有媒体附件（图片、音频、视频、封面、文件、资源）的列表，且 URL 有效
  List<Attachment> get mediaAttachments {
    final result = <Attachment>[];
    for (final item in [image, audio, video, cover, file, asset]) {
      if (item != null && item.url?.isNotEmpty == true) result.add(item);
    }
    return result;
  }

  /// 根据消息类型 [type] 设置对应的媒体附件
  ///
  /// 用于发送消息时，将附件的 kind 标记为对应类型，并支持视频同时传入封面。
  /// 若附件列表为空则返回原对象。
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

  /// 复制当前对象并更新指定字段（不可变更新）
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

  /// 从 JSON 映射创建 [MessagePayload] 实例
  ///
  /// 根据 JSON 结构自动识别消息类型：
  /// - `text` / `richText`：文本或富文本消息
  /// - `image`：图片消息
  /// - `file`：文件消息
  /// - `audio`：音频消息（含波形、时长）
  /// - `video`：视频消息（含封面、时长）
  /// - `emoji`：表情消息
  /// - `location`：位置消息
  /// - `card`：卡片消息（如链接预览）
  /// - `system`：系统消息
  ///
  /// 支持多种字段别名（兼容不同后端协议）。
  factory MessagePayload.fromJson(Map<String, dynamic> json) {
    // -------- 文本消息（普通文本） --------
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

    // -------- 富文本消息（Quill Delta） --------
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

    // -------- 图片消息 --------
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

    // -------- 文件消息 --------
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

    // -------- 音频消息 --------
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

    // -------- 视频消息 --------
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

    // -------- 表情消息 --------
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

    // -------- 位置消息 --------
    final location = _asMap(json['location']);
    if (location != null) {
      final title = _readString(location, ['title']);
      final address = _readString(location, ['address']);
      return MessagePayload(content: title.isNotEmpty ? title : address);
    }

    // -------- 卡片消息（如链接预览） --------
    final card = _asMap(json['card']);
    if (card != null) {
      final title = _readString(card, ['title']);
      final summary = _readString(card, ['summary']);
      return MessagePayload(content: title.isNotEmpty ? title : summary);
    }

    // -------- 系统消息 --------
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

    // -------- 通用兜底解析 --------
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

  /// 将当前对象转换为 JSON 映射（用于序列化发送）
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

  /// 返回对象的字符串表示（便于调试）
  @override
  String toString() =>
      'MessagePayload{content: $content, quillDelta: $quillDelta, '
      'replyTo: $replyTo, mentions: $mentions, markdown: $markdown, '
      'emojiCode: $emojiCode, audioDuration: $audioDuration, '
      'mediaAttachments: ${mediaAttachments.length}}';

  // -------- 私有辅助方法（用于解析 JSON） --------

  /// 将值安全转换为 Map<String, dynamic>，支持传入普通 Map 或 null
  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// 从 [source] 中按 [keys] 顺序读取第一个非空字符串并返回
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

  /// 从 interaction 中读取 replyTo 字段（支持多种别名）
  static String _readReplyTo(Map<String, dynamic>? interaction) => _readString(
    interaction,
    ['replyToMessageId', 'reply_to_message_id', 'replyTo'],
  );

  /// 从 interaction 中读取 mentions（@提及用户 ID 列表）
  static List<int>? _readMentions(Map<String, dynamic>? interaction) =>
      _readIntList(interaction?['mentionUserIds'] ?? interaction?['mentions']);

  /// 将值解析为 int（支持字符串或数字），无法解析则返回 null
  static int? _readInt(dynamic value) =>
      value == null ? null : int.tryParse(value.toString());

  /// 将列表中的每个元素转换为 int，返回非空列表，若列表为空或无效则返回 null
  static List<int>? _readIntList(dynamic value) {
    if (value is! List) return null;
    final result = value
        .map((e) => int.tryParse(e.toString()))
        .whereType<int>()
        .toList();
    return result.isEmpty ? null : result;
  }

  /// 从 JSON 中读取 Attachment 对象，若 URL 无效则返回 null
  static Attachment? _readAttachment(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    final attachment = Attachment.fromJson(map);
    if (attachment.url?.isNotEmpty != true) return null;
    return attachment;
  }
}
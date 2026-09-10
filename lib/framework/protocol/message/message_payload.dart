import 'dart:convert';

import 'attachment.dart';
import 'code_payload.dart';
import 'message_enum.dart';
import 'message_payload_parts.dart';

export 'message_payload_parts.dart';

/// @全体成员的固定占位用户 ID。
///
/// 群聊提及列表中的「@所有人」项以该 ID 写入 mention embed，
/// 发送时从 [MessagePayload.mentions] 中排除，避免误提醒真实用户，
/// 通过 [MessagePayload.mentionAll] 标记（写入 interaction.mentionAll）。
const int kMentionAllUserId = -1;

/// 消息载荷（V6 协议）
///
/// 这是各种类型消息的通用载荷容器，包含了文本、富文本、媒体、位置、卡片等多种内容。
/// 根据 [MessageType] 的不同，使用 [toTypedJson] 生成对应结构供服务端使用，
/// 而 [fromJson] 可以自动识别并解析服务端下发的各种消息格式。
///
/// 所有字段均为可选，实际使用中只有与消息类型相关的字段才会被填充。
class MessagePayload {
  // ==================== 基础文本/内容 ====================

  /// 纯文本内容（普通文本消息、媒体描述、系统消息文本）
  final String? content;

  /// Quill 富文本的 Delta JSON 字符串（用于富文本消息）
  final String? quillDelta;

  /// 回复的目标消息 ID（用于引用回复）
  final String? replyTo;

  /// 被 @ 的用户 ID 列表
  final List<int>? mentions;

  /// 是否 @了房间内所有人（群聊「@所有人」）
  final bool? mentionAll;

  /// Markdown 格式文本（可选）
  final String? markdown;

  /// Emoji 唯一标识码
  final String? emojiCode;

  /// 音频时长（毫秒）
  final int? audioDuration;

  // ==================== 媒体附件 ====================

  /// 图片附件
  final Attachment? image;

  /// 音频附件
  final Attachment? audio;

  /// 视频附件
  final Attachment? video;

  /// 视频封面图（缩略图）
  final Attachment? cover;

  /// 文件附件（通用文档）
  final Attachment? file;

  /// 资源附件（如表情包原始文件）
  final Attachment? asset;

  /// 音频波形数据（Base64 字符串）
  final String? waveform;

  // ==================== 结构化载荷 ====================

  /// 位置信息
  final LocationPayload? location;

  /// 卡片信息
  final CardPayload? card;

  /// 代码信息
  final CodePayload? code;

  /// 服务端生成的系统消息信息
  final SystemPayload? system;

  // ==================== 构造函数 ====================

  const MessagePayload({
    this.content,
    this.quillDelta,
    this.replyTo,
    this.mentions,
    this.mentionAll,
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
    this.location,
    this.card,
    this.code,
    this.system,
  });

  // ==================== 辅助方法 ====================

  /// 获取所有媒体附件（图片、音频、视频、封面、文件、资产）中有效的列表。
  List<Attachment> get mediaAttachments {
    final result = <Attachment>[];
    for (final item in [image, audio, video, cover, file, asset]) {
      if (item != null && item.url?.isNotEmpty == true) result.add(item);
    }
    return result;
  }

  /// 根据消息类型和附件列表生成新的 [MessagePayload]。
  /// 常用于发送媒体消息时自动填充附件字段。
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

  /// 创建副本并选择性更新字段。
  MessagePayload copyWith({
    String? content,
    String? quillDelta,
    String? replyTo,
    List<int>? mentions,
    bool? mentionAll,
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
    LocationPayload? location,
    CardPayload? card,
    CodePayload? code,
    SystemPayload? system,
  }) => MessagePayload(
    content: content ?? this.content,
    quillDelta: quillDelta ?? this.quillDelta,
    replyTo: replyTo ?? this.replyTo,
    mentions: mentions ?? this.mentions,
    mentionAll: mentionAll ?? this.mentionAll,
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
    location: location ?? this.location,
    card: card ?? this.card,
    code: code ?? this.code,
    system: system ?? this.system,
  );

  // ==================== JSON 序列化 / 反序列化 ====================

  /// 从 JSON 解析 [MessagePayload]。
  ///
  /// 该方法会自动检测输入 JSON 的结构（如 `text`、`image`、`audio` 等顶层字段），
  /// 并从中提取相应字段，支持服务端多种命名风格。
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
        mentionAll: _readMentionAll(interaction),
      );
    }

    final richText = _asMap(json['richText']);
    if (richText != null) {
      final interaction = _asMap(richText['interaction']);
      final quillDelta = _readString(richText, [
        'deltaJson',
        'delta_json',
        'quillDelta',
        'quill_delta',
      ]);
      return MessagePayload(
        content: _readString(richText, ['plainText', 'plain_text', 'content']),
        quillDelta: quillDelta,
        replyTo: _readReplyTo(interaction),
        mentions: _readMentions(interaction),
        mentionAll:
            _readMentionAll(interaction) ?? deltaMentionsAll(quillDelta),
      );
    }

    final imagePayload = _asMap(json['image']);
    if (imagePayload != null) {
      final interaction = _asMap(imagePayload['interaction']);
      final nestedContent = _readString(imagePayload, ['caption', 'content']);
      return MessagePayload(
        content: nestedContent.isNotEmpty
            ? nestedContent
            : _readString(json, ['content']),
        // Typed wire JSON wraps the attachment in `image.image`, while the
        // local-cache/debug representation stores the attachment directly in
        // the top-level `image` field. Support both forms.
        image: _readAttachment(
          imagePayload['image'] ?? imagePayload,
        )?.copyWith(kind: 'IMAGE'),
        replyTo: _readReplyTo(interaction).isNotEmpty
            ? _readReplyTo(interaction)
            : _readString(json, ['replyTo', 'reply_to']),
        mentions: _readMentions(interaction) ?? _readIntList(json['mentions']),
        mentionAll:
            _readMentionAll(interaction) ?? _readBool(json['mentionAll']),
      );
    }

    final filePayload = _asMap(json['file']);
    if (filePayload != null) {
      final interaction = _asMap(filePayload['interaction']);
      final nestedContent = _readString(filePayload, ['caption', 'content']);
      return MessagePayload(
        content: nestedContent.isNotEmpty
            ? nestedContent
            : _readString(json, ['content']),
        // See the image branch above: persisted flat payloads do not contain
        // an additional `file` wrapper.
        file: _readAttachment(
          filePayload['file'] ?? filePayload,
        )?.copyWith(kind: 'FILE'),
        replyTo: _readReplyTo(interaction).isNotEmpty
            ? _readReplyTo(interaction)
            : _readString(json, ['replyTo', 'reply_to']),
        mentions: _readMentions(interaction) ?? _readIntList(json['mentions']),
        mentionAll:
            _readMentionAll(interaction) ?? _readBool(json['mentionAll']),
      );
    }

    final audioPayload = _asMap(json['audio']);
    if (audioPayload != null) {
      return MessagePayload(
        content: '[audio]',
        // 本地平铺 JSON（toFlatJson）把 audioDuration 放在顶层，
        // 服务端嵌套 JSON 放在 audio.durationMs，两种形式都要兼容，
        // 否则本地缓存往返会丢失语音时长（渲染恒为 0）。
        audioDuration: _readInt(
          audioPayload['durationMs'] ??
              audioPayload['duration_ms'] ??
              json['audioDuration'],
        ),
        // 与 image 分支一致：服务端嵌套 JSON 是 audio.audio，本地平铺 JSON
        // 直接把附件放在顶层 audio 字段，两种形式都要兼容，否则缓存往返
        // 会丢失语音附件。
        audio: _readAttachment(
          audioPayload['audio'] ?? audioPayload,
        )?.copyWith(kind: 'AUDIO'),
        waveform: _readString(audioPayload, ['waveform']).isNotEmpty
            ? _readString(audioPayload, ['waveform'])
            : _readString(json, ['waveform']),
      );
    }

    final videoPayload = _asMap(json['video']);
    if (videoPayload != null) {
      final interaction = _asMap(videoPayload['interaction']);
      final caption = _readString(videoPayload, ['caption', 'content']);
      final replyTo = _readReplyTo(interaction);
      return MessagePayload(
        content: caption.isNotEmpty
            ? caption
            : _readString(json, ['content']).isNotEmpty
            ? _readString(json, ['content'])
            : '[video]',
        replyTo: replyTo.isNotEmpty
            ? replyTo
            : _readString(json, ['replyTo', 'reply_to']),
        mentions: _readMentions(interaction) ?? _readIntList(json['mentions']),
        mentionAll:
            _readMentionAll(interaction) ?? _readBool(json['mentionAll']),
        audioDuration: _readInt(
          videoPayload['durationMs'] ??
              videoPayload['duration_ms'] ??
              json['audioDuration'],
        ),
        // 服务端 typed JSON 使用 video.video，本地缓存的 flat JSON 则直接
        // 把附件存放在顶层 video 字段。两种形式都必须支持，否则发送中的
        // 视频落库再读回后会丢失附件，消息气泡最终渲染为空。
        video: _readAttachment(
          videoPayload['video'] ?? videoPayload,
        )?.copyWith(kind: 'VIDEO'),
        cover: _readAttachment(
          videoPayload['cover'] ?? json['cover'],
        )?.copyWith(kind: 'IMAGE'),
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
      final locationPayload = LocationPayload.fromJson(location);
      return MessagePayload(
        content: locationPayload.displayTitle,
        location: locationPayload,
      );
    }

    final cardMap = _asMap(json['card']);
    if (cardMap != null) {
      final card = CardPayload.fromJson(cardMap);
      return MessagePayload(
        content: card.displayTitle.isNotEmpty
            ? card.displayTitle
            : card.displaySummary,
        card: card,
      );
    }

    final codeMap = _asMap(json['code']);
    if (codeMap != null) {
      final code = CodePayload.fromJson(codeMap);
      final interaction = _asMap(codeMap['interaction']);
      // 本地预览优先标题/代码首行；语言名（如 dart/plaintext）不是用户内容，
      // 不做 content，避免会话列表出现语言原文或 [code] 占位。
      final topContent = _readString(json, ['content']);
      return MessagePayload(
        content: topContent.isNotEmpty
            ? topContent
            : code.previewSnippet,
        code: code,
        replyTo: _readReplyTo(interaction).isNotEmpty
            ? _readReplyTo(interaction)
            : _readString(json, ['replyTo', 'reply_to']),
        mentions: _readMentions(interaction) ?? _readIntList(json['mentions']),
        mentionAll:
            _readMentionAll(interaction) ?? _readBool(json['mentionAll']),
      );
    }

    final systemMap = _asMap(json['system']);
    if (systemMap != null) {
      final system = SystemPayload.fromJson(systemMap);
      return MessagePayload(
        content:
            system.text ?? system.eventCode ?? _readString(json, ['content']),
        system: system,
      );
    }

    // 兜底：尝试平铺字段
    final flatCard = _readFlatCard(json);
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
      mentionAll: _readBool(json['mentionAll'] ?? json['mention_all']),
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
      location: _readFlatLocation(json),
      card: flatCard,
    );
  }

  /// 序列化为平铺 JSON（所有字段在同一层级），用于存储或调试。
  Map<String, dynamic> toJson() => toFlatJson();

  /// 生成平铺 JSON。
  Map<String, dynamic> toFlatJson() => {
    'content': content,
    'quillDelta': quillDelta,
    'replyTo': replyTo,
    'mentions': mentions,
    'mentionAll': mentionAll,
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
    'location': location?.toJson(),
    'card': card?.toJson(),
    'code': code?.toJson(),
    'system': system?.toJson(),
  };

  /// 根据消息类型生成服务端要求的嵌套 JSON 结构。
  Map<String, dynamic> toTypedJson(MessageType type) {
    final interaction = _buildInteractionJson();
    return switch (type) {
      MessageType.text => {
        'text': {
          'text': content,
          if (markdown?.isNotEmpty == true) 'markdown': markdown,
          'interaction': ?interaction,
        },
      },
      MessageType.richText => {
        'richText': {
          'plainText': content,
          'deltaJson': quillDelta,
          'interaction': ?interaction,
        },
      },
      MessageType.image => {
        'image': {
          'image': image?.toJson(),
          'caption': content,
          'interaction': ?interaction,
        },
      },
      MessageType.audio => {
        'audio': {
          'audio': audio?.toJson(),
          'durationMs': audioDuration,
          'waveform': waveform,
        },
      },
      MessageType.video => {
        'video': {
          'video': video?.toJson(),
          'cover': cover?.toJson(),
          'durationMs': audioDuration,
          'caption': content,
          'interaction': ?interaction,
        },
      },
      MessageType.file => {
        'file': {
          'file': file?.toJson(),
          'caption': content,
          'interaction': ?interaction,
        },
      },
      MessageType.emoji => {
        'emoji': {
          'emojiId': emojiCode ?? content,
          'textFallback': content,
          'asset': asset?.toJson(),
        },
      },
      MessageType.location => {
        'location':
            (location ?? LocationPayload(title: content ?? '[location]'))
                .toJson(),
      },
      MessageType.card => {
        'card': (card ?? CardPayload(title: content ?? '[card]')).toJson(),
      },
      MessageType.codeSnippet => {
        'code': {
          ...(code ?? CodePayload(code: content ?? '')).toJson(),
          'interaction': ?interaction,
        },
      },
      MessageType.system => {
        'system': (system ?? SystemPayload(text: content)).toJson(),
      },
    };
  }

  // ==================== 私有工具方法（委托至 message_payload_parts.dart 共享实现） ====================

  /// 将任意值安全转为 `Map<String, dynamic>`。
  static Map<String, dynamic>? _asMap(dynamic value) => payloadAsMap(value);

  /// 从 Map 中按优先级读取第一个非空字符串。
  static String _readString(Map<String, dynamic>? source, List<String> keys) =>
      payloadReadString(source, keys);

  /// 从 interaction 对象中读取 replyTo。
  static String _readReplyTo(Map<String, dynamic>? interaction) => _readString(
    interaction,
    ['replyToMessageId', 'reply_to_message_id', 'replyTo'],
  );

  /// 从 interaction 对象中读取 mentions 列表。
  static List<int>? _readMentions(Map<String, dynamic>? interaction) =>
      _readIntList(interaction?['mentionUserIds'] ?? interaction?['mentions']);

  /// 从 interaction 对象中读取是否 @所有人。
  static bool? _readMentionAll(Map<String, dynamic>? interaction) =>
      _readBool(interaction?['mentionAll'] ?? interaction?['mention_all']);

  /// 将动态值转为 bool。
  static bool? _readBool(dynamic value) => payloadReadBool(value);

  /// 将动态值转为 int。
  static int? _readInt(dynamic value) => payloadReadInt(value);

  /// 将动态值转为 double。
  static double? _readDouble(dynamic value) => payloadReadDouble(value);

  /// 将动态值转为 int 列表。
  static List<int>? _readIntList(dynamic value) => payloadReadIntList(value);

  /// 从 Quill Delta JSON 中检测是否包含「@所有人」提及。
  ///
  /// 富文本消息的 interaction.mentionUserIds 不含占位 ID，
  /// 「@所有人」标记只存在于 delta 的 mention embed（userId == -1）中，
  /// 接收侧（含本地缓存回放）以此兜底识别。
  static bool deltaMentionsAll(String? quillDelta) {
    if (quillDelta == null || quillDelta.isEmpty) return false;
    try {
      final dynamic ops = jsonDecode(quillDelta);
      if (ops is! List) return false;
      for (final op in ops) {
        if (op is! Map) continue;
        final insert = op['insert'];
        if (insert is! Map) continue;
        if (!insert.containsKey('mention')) continue;
        final dynamic mention = insert['mention'];
        Map<String, dynamic>? mentionMap;
        if (mention is String) {
          mentionMap = Map<String, dynamic>.from(jsonDecode(mention) as Map);
        } else if (mention is Map) {
          mentionMap = Map<String, dynamic>.from(mention);
        }
        if (mentionMap != null && mentionMap['userId'] == kMentionAllUserId) {
          return true;
        }
      }
    } catch (_) {
      // 非法 delta 视为不含 @所有人。
    }
    return false;
  }

  /// 从 JSON 中读取附件，若 URL 为空则返回 null。
  static Attachment? _readAttachment(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    final attachment = Attachment.fromJson(map);
    if (attachment.url?.isNotEmpty != true) return null;
    return attachment;
  }

  /// 构建 interaction 对象（用于回复和 @ 功能）。
  Map<String, dynamic>? _buildInteractionJson() {
    if ((replyTo == null || replyTo!.isEmpty) &&
        (mentions == null || mentions!.isEmpty) &&
        mentionAll != true) {
      return null;
    }
    return {
      'replyToMessageId': replyTo,
      'mentionUserIds': mentions,
      if (mentionAll == true) 'mentionAll': true,
    };
  }

  /// 尝试从平铺 JSON 中解析卡片（当无顶层 'card' 时备用）。
  static CardPayload? _readFlatCard(Map<String, dynamic> json) {
    final hasCardField = [
      'cardType',
      'card_type',
      'entityId',
      'entity_id',
      'title',
      'summary',
      'thumbnailUrl',
      'thumbnail_url',
    ].any((key) => json[key]?.toString().trim().isNotEmpty == true);
    if (!hasCardField) return null;
    return CardPayload.fromJson(json);
  }

  /// 尝试从平铺 JSON 中解析位置（当无顶层 'location' 时备用）。
  static LocationPayload? _readFlatLocation(Map<String, dynamic> json) {
    final hasLocationField = [
      'latitude',
      'lat',
      'longitude',
      'lng',
      'address',
    ].any((key) => json[key]?.toString().trim().isNotEmpty == true);
    if (!hasLocationField) return null;
    return LocationPayload(
      latitude: _readDouble(json['latitude'] ?? json['lat']),
      longitude: _readDouble(json['longitude'] ?? json['lng']),
      title: _readString(json, ['title', 'name', 'content']),
      address: _readString(json, ['address', 'addr']),
    );
  }

  // ==================== 字符串表示 ====================

  @override
  String toString() {
    return 'MessagePayload{\n'
        '  content: $content,\n'
        '  quillDelta: $quillDelta,\n'
        '  replyTo: $replyTo,\n'
        '  mentions: $mentions,\n'
        '  mentionAll: $mentionAll,\n'
        '  markdown: $markdown,\n'
        '  emojiCode: $emojiCode,\n'
        '  audioDuration: $audioDuration,\n'
        '  image: ${image != null ? 'Attachment(...)' : 'null'},\n'
        '  audio: ${audio != null ? 'Attachment(...)' : 'null'},\n'
        '  video: ${video != null ? 'Attachment(...)' : 'null'},\n'
        '  cover: ${cover != null ? 'Attachment(...)' : 'null'},\n'
        '  file: ${file != null ? 'Attachment(...)' : 'null'},\n'
        '  asset: ${asset != null ? 'Attachment(...)' : 'null'},\n'
        '  waveform: $waveform,\n'
        '  location: $location,\n'
        '  card: $card,\n'
        '  mediaAttachments: ${mediaAttachments.length}\n'
        '}';
  }
}

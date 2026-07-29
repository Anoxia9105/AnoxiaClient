import 'attachment.dart';
import 'message_eunm.dart';

/// 卡片消息载荷（V5 协议）
///
/// 用于表示富媒体卡片类型消息，如联系人卡片、群组卡片、链接预览等。
/// 支持灵活的字段映射，兼容服务端多种命名风格（如 `card_type` / `cardType`）。
class CardPayload {
  // ==================== 字段 ====================

  /// 卡片类型标识（如 'contact', 'group', 'link' 等）
  final String? cardType;

  /// 卡片关联的实体 ID（如用户 ID、群组 ID、文章 ID）
  final String? entityId;

  /// 卡片标题
  final String? title;

  /// 卡片摘要/描述
  final String? summary;

  /// 缩略图 URL
  final String? thumbnailUrl;

  /// 扩展属性键值对
  final Map<String, String> properties;

  // ==================== 构造函数 ====================

  /// 构造 [CardPayload] 实例。
  const CardPayload({
    this.cardType,
    this.entityId,
    this.title,
    this.summary,
    this.thumbnailUrl,
    this.properties = const {},
  });

  /// 从 JSON 反序列化，兼容多种字段命名。
  factory CardPayload.fromJson(Map<String, dynamic> json) => CardPayload(
    cardType: _readString(json, ['cardType', 'card_type', 'type']),
    entityId: _readString(json, ['entityId', 'entity_id', 'id']),
    title: _readString(json, ['title', 'name']),
    summary: _readString(json, ['summary', 'desc', 'description', 'content']),
    thumbnailUrl: _readString(json, [
      'thumbnailUrl',
      'thumbnail_url',
      'avatar',
      'image',
      'imageUrl',
      'image_url',
    ]),
    properties: _readStringMap(json['properties'] ?? json['extra']),
  );

  /// 序列化为 JSON Map。
  Map<String, dynamic> toJson() => {
    'cardType': cardType,
    'entityId': entityId,
    'title': title,
    'summary': summary,
    'thumbnailUrl': thumbnailUrl,
    'properties': properties,
  };

  /// 创建副本并选择性更新字段。
  CardPayload copyWith({
    String? cardType,
    String? entityId,
    String? title,
    String? summary,
    String? thumbnailUrl,
    Map<String, String>? properties,
  }) => CardPayload(
    cardType: cardType ?? this.cardType,
    entityId: entityId ?? this.entityId,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    properties: properties ?? this.properties,
  );

  // ==================== 辅助显示 ====================

  /// 获取优先用于展示的标题，依次尝试 title、entityId、cardType。
  String get displayTitle => _firstNotEmpty([title, entityId, cardType]);

  /// 获取优先用于展示的摘要，仅尝试 summary。
  String get displaySummary => _firstNotEmpty([summary]);

  // ==================== 私有工具方法 ====================

  /// 从 Map 中按优先级读取第一个非空字符串。
  static String? _readString(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  /// 将任意值转换为 `Map<String, String>`。
  static Map<String, String> _readStringMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, val) => MapEntry(key.toString(), val.toString()));
  }

  /// 从字符串列表中返回第一个非空字符串（去除首尾空格）。
  static String _firstNotEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '';
  }

  // ==================== 字符串表示 ====================

  @override
  String toString() {
    return 'CardPayload{\n'
        '  cardType: $cardType,\n'
        '  entityId: $entityId,\n'
        '  title: $title,\n'
        '  summary: $summary,\n'
        '  thumbnailUrl: $thumbnailUrl,\n'
        '  properties: $properties\n'
        '}';
  }
}

/// 位置消息载荷（V5 协议）
///
/// 用于表示地理位置消息，包含经纬度坐标及地点名称、地址信息。
class LocationPayload {
  // ==================== 字段 ====================

  /// 纬度
  final double? latitude;

  /// 经度
  final double? longitude;

  /// 地点名称（如“钟楼”）
  final String? title;

  /// 详细地址（如“西安市莲湖区北大街”）
  final String? address;

  // ==================== 构造函数 ====================

  const LocationPayload({
    this.latitude,
    this.longitude,
    this.title,
    this.address,
  });

  /// 从 JSON 反序列化，支持 `lat`/`lng` 别名。
  factory LocationPayload.fromJson(Map<String, dynamic> json) =>
      LocationPayload(
        latitude: _readDouble(json['latitude'] ?? json['lat']),
        longitude: _readDouble(json['longitude'] ?? json['lng']),
        title: _readString(json, ['title', 'name']),
        address: _readString(json, ['address', 'addr']),
      );

  /// 序列化为 JSON Map。
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'title': title,
    'address': address,
  };

  /// 创建副本并选择性更新字段。
  LocationPayload copyWith({
    double? latitude,
    double? longitude,
    String? title,
    String? address,
  }) => LocationPayload(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    title: title ?? this.title,
    address: address ?? this.address,
  );

  // ==================== 辅助显示 ====================

  /// 获取优先展示的标题（首选 title，否则地址）。
  String get displayTitle => _firstNotEmpty([title, address]);

  /// 获取展示地址。
  String get displayAddress => _firstNotEmpty([address]);

  /// 是否包含有效坐标。
  bool get hasCoordinate => latitude != null && longitude != null;

  // ==================== 私有工具方法 ====================

  /// 将动态值转为 double。
  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// 从 Map 中按优先级读取第一个非空字符串。
  static String? _readString(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  /// 从字符串列表中返回第一个非空字符串。
  static String _firstNotEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '';
  }

  // ==================== 字符串表示 ====================

  @override
  String toString() {
    return 'LocationPayload{\n'
        '  latitude: $latitude,\n'
        '  longitude: $longitude,\n'
        '  title: $title,\n'
        '  address: $address\n'
        '}';
  }
}

/// 消息载荷（V5 协议）
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

  // ==================== 构造函数 ====================

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
    this.location,
    this.card,
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
    location: location ?? this.location,
    card: card ?? this.card,
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
      MessageType.system => {
        'system': {'text': content, 'eventCode': content},
      },
    };
  }

  // ==================== 私有工具方法 ====================

  /// 将任意值安全转为 Map<String, dynamic>。
  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// 从 Map 中按优先级读取第一个非空字符串。
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

  /// 从 interaction 对象中读取 replyTo。
  static String _readReplyTo(Map<String, dynamic>? interaction) => _readString(
    interaction,
    ['replyToMessageId', 'reply_to_message_id', 'replyTo'],
  );

  /// 从 interaction 对象中读取 mentions 列表。
  static List<int>? _readMentions(Map<String, dynamic>? interaction) =>
      _readIntList(interaction?['mentionUserIds'] ?? interaction?['mentions']);

  /// 将动态值转为 int。
  static int? _readInt(dynamic value) =>
      value == null ? null : int.tryParse(value.toString());

  /// 将动态值转为 double。
  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// 将动态值转为 int 列表。
  static List<int>? _readIntList(dynamic value) {
    if (value is! List) return null;
    final result = value
        .map((e) => int.tryParse(e.toString()))
        .whereType<int>()
        .toList();
    return result.isEmpty ? null : result;
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
        (mentions == null || mentions!.isEmpty)) {
      return null;
    }
    return {'replyToMessageId': replyTo, 'mentionUserIds': mentions};
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

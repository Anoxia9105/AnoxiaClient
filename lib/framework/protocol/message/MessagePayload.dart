import 'Attachment.dart';
import 'MessageEunm.dart';

class CardPayload {
  final String? cardType;
  final String? entityId;
  final String? title;
  final String? summary;
  final String? thumbnailUrl;
  final Map<String, String> properties;

  const CardPayload({
    this.cardType,
    this.entityId,
    this.title,
    this.summary,
    this.thumbnailUrl,
    this.properties = const {},
  });

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

  Map<String, dynamic> toJson() => {
    'cardType': cardType,
    'entityId': entityId,
    'title': title,
    'summary': summary,
    'thumbnailUrl': thumbnailUrl,
    'properties': properties,
  };

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

  String get displayTitle => _firstNotEmpty([title, entityId, cardType]);
  String get displaySummary => _firstNotEmpty([summary]);

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

  static Map<String, String> _readStringMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, val) => MapEntry(key.toString(), val.toString()));
  }

  static String _firstNotEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '';
  }
}

class LocationPayload {
  final double? latitude;
  final double? longitude;
  final String? title;
  final String? address;

  const LocationPayload({
    this.latitude,
    this.longitude,
    this.title,
    this.address,
  });

  factory LocationPayload.fromJson(Map<String, dynamic> json) =>
      LocationPayload(
        latitude: _readDouble(json['latitude'] ?? json['lat']),
        longitude: _readDouble(json['longitude'] ?? json['lng']),
        title: _readString(json, ['title', 'name']),
        address: _readString(json, ['address', 'addr']),
      );

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'title': title,
    'address': address,
  };

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

  String get displayTitle => _firstNotEmpty([title, address]);
  String get displayAddress => _firstNotEmpty([address]);
  bool get hasCoordinate => latitude != null && longitude != null;

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

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

  static String _firstNotEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '';
  }
}

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
  final LocationPayload? location;
  final CardPayload? card;

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

  Map<String, dynamic> toJson() => toFlatJson();

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

  Map<String, dynamic> toTypedJson(MessageType type) {
    final interaction = _buildInteractionJson();
    return switch (type) {
      MessageType.text => {
        'text': {
          'text': content,
          if (markdown?.isNotEmpty == true) 'markdown': markdown,
          if (interaction != null) 'interaction': interaction,
        },
      },
      MessageType.richText => {
        'richText': {
          'plainText': content,
          'deltaJson': quillDelta,
          if (interaction != null) 'interaction': interaction,
        },
      },
      MessageType.image => {
        'image': {
          'image': image?.toJson(),
          'caption': content,
          if (interaction != null) 'interaction': interaction,
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
          if (interaction != null) 'interaction': interaction,
        },
      },
      MessageType.file => {
        'file': {
          'file': file?.toJson(),
          'caption': content,
          if (interaction != null) 'interaction': interaction,
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

  @override
  String toString() =>
      'MessagePayload{content: $content, quillDelta: $quillDelta, '
      'replyTo: $replyTo, mentions: $mentions, markdown: $markdown, '
      'emojiCode: $emojiCode, audioDuration: $audioDuration, '
      'mediaAttachments: ${mediaAttachments.length}, location: $location, '
      'card: $card}';

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

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

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

  Map<String, dynamic>? _buildInteractionJson() {
    if ((replyTo == null || replyTo!.isEmpty) &&
        (mentions == null || mentions!.isEmpty)) {
      return null;
    }
    return {'replyToMessageId': replyTo, 'mentionUserIds': mentions};
  }

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
}

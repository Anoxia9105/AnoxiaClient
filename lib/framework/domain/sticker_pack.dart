/// 表情包模型（服务端 /chat/sticker/packs 数据源）
///
/// 表情包内的每个 [Sticker] 是一张图片表情，发送时以
/// [emojiCode] = stickerKey + asset(图片 URL/宽高) 构造 Emoji 消息。
class StickerPack {
  final int id;
  final String name;
  final String iconUrl;
  final List<Sticker> stickers;

  /// 所属用户ID（服务端全局表情包为 null，用户自定义表情包为登录用户ID）
  final int? userId;

  const StickerPack({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.stickers,
    this.userId,
  });

  /// 是否为用户自定义表情包（区别于服务端全局表情包）
  bool get isCustom => userId != null;

  /// 从 JSON 构造 [StickerPack]，兼容 camelCase 与 snake_case
  factory StickerPack.fromJson(Map<String, dynamic> json) {
    final rawStickers = json['stickers'];
    final stickers = rawStickers is List
        ? rawStickers
              .whereType<Map>()
              .map((e) => Sticker.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const <Sticker>[];
    return StickerPack(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name:
          json['name']?.toString() ??
          json['packName']?.toString() ??
          json['pack_name']?.toString() ??
          '',
      iconUrl:
          json['iconUrl']?.toString() ?? json['icon_url']?.toString() ?? '',
      userId: int.tryParse(
        json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      ),
      stickers: stickers,
    );
  }
}

/// 单个图片表情
class Sticker {
  final int id;
  final int packId;
  final String stickerKey;
  final String imageUrl;
  final int? width;
  final int? height;

  const Sticker({
    required this.id,
    required this.packId,
    required this.stickerKey,
    required this.imageUrl,
    this.width,
    this.height,
  });

  /// 从 JSON 构造 [Sticker]，兼容 camelCase 与 snake_case
  factory Sticker.fromJson(Map<String, dynamic> json) {
    return Sticker(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      packId: int.tryParse(json['packId']?.toString() ?? '') ?? 0,
      stickerKey:
          json['stickerKey']?.toString() ?? json['sticker_key']?.toString() ??
          '',
      imageUrl:
          json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? '',
      width: int.tryParse(json['width']?.toString() ?? ''),
      height: int.tryParse(json['height']?.toString() ?? ''),
    );
  }
}

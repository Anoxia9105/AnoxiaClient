import 'package:anoxia/framework/domain/sticker_pack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StickerPack 解析', () {
    test('全局表情包 userId 为 null，isCustom 为 false', () {
      final pack = StickerPack.fromJson({
        'id': 1,
        'name': '经典笑脸',
        'iconUrl': 'https://example.com/icon.png',
        'stickers': [
          {
            'id': 11,
            'packId': 1,
            'stickerKey': '1f600',
            'imageUrl': 'https://example.com/1f600.png',
            'width': 72,
            'height': 72,
          },
        ],
      });

      expect(pack.id, 1);
      expect(pack.userId, isNull);
      expect(pack.isCustom, isFalse);
      expect(pack.stickers, hasLength(1));
      expect(pack.stickers.first.width, 72);
    });

    test('用户自定义表情包 userId 非空，isCustom 为 true', () {
      final pack = StickerPack.fromJson({
        'id': 99,
        'name': '我的表情包',
        'iconUrl': 'https://example.com/custom.png',
        'userId': 42,
        'stickers': <Map<String, dynamic>>[],
      });

      expect(pack.userId, 42);
      expect(pack.isCustom, isTrue);
    });

    test('兼容 snake_case 的 user_id 字段', () {
      final pack = StickerPack.fromJson({
        'id': 100,
        'name': '自定义',
        'icon_url': 'https://example.com/custom.png',
        'user_id': '7',
        'stickers': <Map<String, dynamic>>[],
      });

      expect(pack.userId, 7);
      expect(pack.iconUrl, 'https://example.com/custom.png');
      expect(pack.isCustom, isTrue);
    });
  });
}

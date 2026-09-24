import 'package:anoxia/common/widgets/cached_network_image_view.dart';
import 'package:anoxia/framework/domain/sticker_pack.dart';
import 'package:cross_cache/cross_cache.dart' as cross_cache;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Web GIF 可优先使用浏览器原生图片元素', () {
    expect(
      shouldPreferWebHtmlElement(isWeb: true, preferWebHtmlElement: true),
      isTrue,
    );
    expect(
      shouldPreferWebHtmlElement(isWeb: true, preferWebHtmlElement: false),
      isFalse,
    );
    expect(
      shouldPreferWebHtmlElement(isWeb: false, preferWebHtmlElement: true),
      isFalse,
    );
  });

  test('表情 GIF 识别忽略大小写和查询参数', () {
    const gif = Sticker(
      id: 1,
      packId: 1,
      stickerKey: 'gif',
      imageUrl: 'https://cdn.example.com/stickers/wave.GIF?token=1',
    );
    const png = Sticker(
      id: 2,
      packId: 1,
      stickerKey: 'png',
      imageUrl: 'https://cdn.example.com/stickers/wave.png?format=gif',
    );

    expect(gif.isGif, isTrue);
    expect(png.isGif, isFalse);
  });

  testWidgets('非 Web 平台仍使用跨平台缓存图片', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    const view = CachedNetworkImageView(
      imageUrl: 'https://cdn.example.com/stickers/wave.gif',
      preferWebHtmlElement: true,
    );

    final image = view.build(context) as Image;

    expect(image.image, isA<cross_cache.CachedNetworkImage>());
  }, skip: kIsWeb);

  testWidgets('浏览器运行时启用原生图片元素策略', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    const view = CachedNetworkImageView(
      imageUrl: 'https://cdn.example.com/stickers/wave.gif',
      preferWebHtmlElement: true,
    );

    final image = view.build(context) as Image;

    expect(
      (image.image as NetworkImage).webHtmlElementStrategy,
      WebHtmlElementStrategy.prefer,
    );
  }, skip: !kIsWeb);
}

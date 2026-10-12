import 'dart:convert';
import 'dart:typed_data';

import 'package:anoxia/common/utils/static_avatar_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('头像根据文件内容拒绝 GIF，改名为 jpg 也不能绕过', () async {
    final renamedJpgBytes = Uint8List.fromList(
      img.encodeGif(img.Image(width: 8, height: 4)),
    );
    expect(isStaticAvatarImage(renamedJpgBytes), isFalse);
    await expectLater(
      decodeStaticAvatarImage(renamedJpgBytes),
      throwsA(isA<FormatException>()),
    );
  });

  test('拒绝 APNG 的动画控制块', () async {
    final image = img.Image(width: 8, height: 4);
    image.addFrame(img.Image(width: 8, height: 4));
    final bytes = Uint8List.fromList(img.encodePng(image));
    expect(isStaticAvatarImage(bytes), isFalse);
    await expectLater(
      decodeStaticAvatarImage(bytes),
      throwsA(isA<FormatException>()),
    );
  });

  test('拒绝 animated WebP 的 VP8X 标志及动画块', () async {
    for (final bytes in [
      _webpChunk('VP8X', [2, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
      _webpChunk('ANIM', [0, 0, 0, 0, 0, 0]),
      _webpChunk('ANMF', List.filled(16, 0)),
    ]) {
      expect(isStaticAvatarImage(bytes), isFalse);
      await expectLater(
        decodeStaticAvatarImage(bytes),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('静态 JPEG、PNG、BMP 正常解码并保留尺寸', () async {
    final source = img.Image(width: 24, height: 12);
    for (final bytes in [
      img.encodeJpg(source),
      img.encodePng(source),
      img.encodeBmp(source),
    ]) {
      final decoded = await decodeStaticAvatarImage(Uint8List.fromList(bytes));
      expect(decoded.width, 24);
      expect(decoded.height, 12);
      decoded.dispose();
    }
  });

  test('静态 WebP 正常解码', () async {
    final bytes = base64Decode(
      'UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA',
    );
    final decoded = await decodeStaticAvatarImage(bytes);
    expect(decoded.width, 1);
    expect(decoded.height, 1);
    decoded.dispose();
  });

  test('伪造图片签名和非图片内容不能解码', () async {
    for (final bytes in [
      Uint8List.fromList(utf8.encode('not an image')),
      Uint8List.fromList([0xff, 0xd8, 0xff, 0, 0, 0]),
      Uint8List.fromList([0x42, 0x4d, 0, 0, 0]),
    ]) {
      await expectLater(decodeStaticAvatarImage(bytes), throwsA(anything));
    }
  });

  test('大图按最长边降采样并保持横竖比例，小图不放大', () async {
    for (final dimensions in [
      (400, 200, 100, 50),
      (200, 400, 50, 100),
      (40, 20, 40, 20),
    ]) {
      final source = img.Image(width: dimensions.$1, height: dimensions.$2);
      final decoded = await decodeStaticAvatarImage(
        Uint8List.fromList(img.encodePng(source)),
        maxSide: 100,
      );
      expect(decoded.width, dimensions.$3);
      expect(decoded.height, dimensions.$4);
      decoded.dispose();
    }
  });
}

Uint8List _webpChunk(String type, List<int> payload) {
  final bytes = Uint8List(20 + payload.length + (payload.length & 1));
  bytes.setRange(0, 4, ascii.encode('RIFF'));
  bytes.setRange(8, 12, ascii.encode('WEBP'));
  bytes.setRange(12, 16, ascii.encode(type));
  final data = ByteData.sublistView(bytes);
  data.setUint32(4, bytes.length - 8, Endian.little);
  data.setUint32(16, payload.length, Endian.little);
  bytes.setRange(20, 20 + payload.length, payload);
  return bytes;
}

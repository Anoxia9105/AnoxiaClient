import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:anoxia/framework/core/notification_call_assets_io.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('默认头像和动作图标生成有效 PNG，并复用缓存', (tester) async {
    await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp('call_assets_');
      try {
        final assets = NotificationCallAssets(directory);
        final avatar = await assets.avatar('张三');
        final icon = await assets.icon(
          'reject',
          HugeIcons.strokeRoundedCallEnd01,
        );
        for (final entry in [(avatar, 160), (icon, 32)]) {
          final bytes = await File.fromUri(entry.$1).readAsBytes();
          expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
          final data = ByteData.sublistView(bytes);
          expect(data.getUint32(16), entry.$2);
          expect(data.getUint32(20), entry.$2);
        }
        final codec = await ui.instantiateImageCodec(
          await File.fromUri(icon).readAsBytes(),
        );
        final image = (await codec.getNextFrame()).image;
        final rgba = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        var visiblePixels = 0;
        for (var offset = 0; offset < rgba.lengthInBytes; offset += 4) {
          if (rgba.getUint8(offset + 3) < 128) continue;
          visiblePixels++;
          expect(
            [
              rgba.getUint8(offset),
              rgba.getUint8(offset + 1),
              rgba.getUint8(offset + 2),
            ],
            [255, 255, 255],
          );
        }
        expect(visiblePixels, greaterThan(0));
        image.dispose();
        codec.dispose();
        final modified = await File.fromUri(avatar).lastModified();
        expect(await assets.avatar('张四'), avatar);
        expect(await File.fromUri(avatar).lastModified(), modified);
        expect(await File.fromUri(await assets.avatar('')).exists(), isTrue);
      } finally {
        await directory.delete(recursive: true);
      }
    });
  });
}

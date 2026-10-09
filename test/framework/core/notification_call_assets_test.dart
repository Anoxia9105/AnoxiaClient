import 'dart:io';
import 'dart:typed_data';
import 'package:anoxia/framework/core/notification_call_assets_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('默认头像和动作图标生成有效 PNG，并复用缓存', (tester) async {
    await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp('call_assets_');
      try {
        final assets = NotificationCallAssets(directory);
        final avatar = await assets.avatar('张三');
        final icon = await assets.icon('reject', Icons.call_end_rounded);
        for (final entry in [(avatar, 160), (icon, 16)]) {
          final bytes = await File.fromUri(entry.$1).readAsBytes();
          expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
          final data = ByteData.sublistView(bytes);
          expect(data.getUint32(16), entry.$2);
          expect(data.getUint32(20), entry.$2);
        }
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

import 'dart:typed_data';

import 'package:anoxia/features/me/presentation/widgets/avatar_crop_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  testWidgets('横向图片裁剪输出指定尺寸的正方形 JPEG', (tester) async {
    final key = GlobalKey<AvatarCropEditorState>();
    final source = img.Image(width: 240, height: 120);
    img.fill(source, color: img.ColorRgb8(240, 80, 30));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AvatarCropEditor(
              key: key,
              imageBytes: Uint8List.fromList(img.encodePng(source)),
              size: 200,
              outputSize: 64,
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    final bytes = await tester.runAsync(
      () async => key.currentState!.cropSquare(),
    );
    expect(bytes, isNotNull);
    expect(bytes!.take(3), [0xff, 0xd8, 0xff]);
    final output = img.decodeJpg(bytes)!;
    expect(output.width, 64);
    expect(output.height, 64);
    final center = output.getPixel(32, 32);
    expect(center.r, closeTo(240, 5));
    expect(center.g, closeTo(80, 5));
    expect(center.b, closeTo(30, 5));
    expect(tester.takeException(), isNull);
  });
}

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:anoxia/domain/models/chat_effect_rule.dart';
import 'package:anoxia/features/chat/presentation/widgets/effects/chat_effect_rain.dart';
import 'package:anoxia/features/chat/presentation/widgets/effects/chat_effect_sprite_atlas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PaintCalls implements Canvas {
  final calls = <Symbol, int>{};
  Invocation? atlasCall;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.update(
      invocation.memberName,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    if (invocation.memberName == #drawRawAtlas) atlasCall = invocation;
    return null;
  }
}

Future<CustomPainter> _startRain(
  WidgetTester tester,
  ChatEffectRule rule,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChatEffectRain(rule: rule, particleCount: 36, onCompleted: () {}),
    ),
  );
  await tester.pump(const Duration(milliseconds: 1400));
  return tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((widget) => widget.painter)
      .whereType<CustomPainter>()
      .single;
}

void main() {
  for (final rule in chatEffectRules) {
    testWidgets('${rule.id} 每帧只批量绘制一次，不合成全屏离屏层或重复绘制文字', (tester) async {
      final painter = await _startRain(tester, rule);
      final canvas = _PaintCalls();
      painter.paint(canvas, const Size(1080, 720));
      expect(canvas.calls[#saveLayer] ?? 0, 0);
      expect(canvas.calls[#drawParagraph] ?? 0, 0);
      expect(canvas.calls[#drawRawAtlas] ?? 0, 1);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('图集按设备像素比生成，重复 emoji 保留权重并共享纹理格', (tester) async {
    final normal = ChatEffectSpriteAtlas(['⭐', '⭐', '🌟'], 1);
    final retina = ChatEffectSpriteAtlas(['⭐', '⭐', '🌟'], 3);
    expect(normal.cells[0], normal.cells[1]);
    expect(normal.cells[0], isNot(normal.cells[2]));
    expect(normal.image.width, normal.cellPixels * 2);
    expect(retina.image.width, retina.cellPixels * 2);
    expect(retina.cellPixels / 3, closeTo(normal.cellPixels.toDouble(), 1));
    normal.dispose();
    retina.dispose();
    expect(normal.image.debugDisposed, isTrue);
    expect(retina.image.debugDisposed, isTrue);
  });

  testWidgets('图片粒子实际可见且动画尾段透明度下降', (tester) async {
    final painter = await _startRain(tester, chatEffectRules.last);
    final canvas = _PaintCalls();
    painter.paint(canvas, const Size(1080, 720));
    int alpha() =>
        ((canvas.atlasCall!.positionalArguments[3] as Int32List).first >> 24) &
        255;
    final initialAlpha = alpha();
    expect(initialAlpha, 230);
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), const Size(1080, 720));
      final picture = recorder.endRecording();
      final image = await picture.toImage(1080, 720);
      final bytes = (await image.toByteData())!;
      var visible = false;
      for (var i = 3; i < bytes.lengthInBytes; i += 4) {
        if (bytes.getUint8(i) > 0) {
          visible = true;
          break;
        }
      }
      expect(visible, isTrue);
      image.dispose();
      picture.dispose();
    });
    await tester.pump(const Duration(milliseconds: 2000));
    painter.paint(canvas, const Size(1080, 720));
    expect(alpha(), lessThan(initialAlpha));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('离屏绘制基准（固定视口、粒子数与进度，不代表真机 FPS）', (tester) async {
    final painter = await _startRain(tester, chatEffectRules.first);
    await tester.runAsync(() async {
      // 前 10 次预热；相同工作量重复 3 轮，计入实际栅格化和像素读回。
      for (var round = -1; round < 3; round++) {
        final timer = Stopwatch()..start();
        final frames = round < 0 ? 10 : 30;
        for (var frame = 0; frame < frames; frame++) {
          final recorder = ui.PictureRecorder();
          painter.paint(Canvas(recorder), const Size(1080, 720));
          final picture = recorder.endRecording();
          final image = await picture.toImage(1080, 720);
          await image.toByteData();
          image.dispose();
          picture.dispose();
        }
        timer.stop();
        if (round >= 0) {
          debugPrint(
            'RAIN_BENCH round=$round us/frame=${timer.elapsedMicroseconds / frames}',
          );
        }
      }
    });
    await tester.pumpWidget(const SizedBox());
  }, skip: !const bool.fromEnvironment('CHAT_EFFECT_BENCHMARK'));
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 将 emoji 一次性栅格化为小纹理，动画帧只提交图片批量绘制。
class ChatEffectSpriteAtlas {
  ChatEffectSpriteAtlas(List<String> emojis, this.pixelRatio) {
    final unique = emojis.toSet().toList();
    final painters = unique.map((emoji) {
      return TextPainter(
        text: TextSpan(
          text: emoji,
          style: const TextStyle(
            fontSize: 32,
            fontFamilyFallback: [
              'Apple Color Emoji',
              'Segoe UI Emoji',
              'Noto Color Emoji',
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }).toList();
    // 每格保留透明边距，旋转及线性采样时不会混入相邻 emoji。
    final extent = painters.fold<double>(
      0,
      (size, painter) =>
          math.max(size, math.max(painter.width, painter.height)),
    );
    cellPixels = ((extent + 8) * pixelRatio).ceil();
    final logicalCell = cellPixels / pixelRatio;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(pixelRatio);
    for (var i = 0; i < painters.length; i++) {
      final painter = painters[i];
      painter.paint(
        canvas,
        Offset(
          i * logicalCell + (logicalCell - painter.width) / 2,
          (logicalCell - painter.height) / 2,
        ),
      );
    }
    final picture = recorder.endRecording();
    try {
      // 返回 GPU 图片句柄，栅格化由引擎异步完成，不逐帧读回像素。
      image = picture.toImageSync(cellPixels * unique.length, cellPixels);
    } finally {
      picture.dispose();
      for (final painter in painters) {
        painter.dispose();
      }
    }
    // 保留规则中的重复项权重，只合并纹理中的相同 emoji。
    cells = emojis.map((emoji) {
      final left = unique.indexOf(emoji) * cellPixels.toDouble();
      return Rect.fromLTWH(
        left,
        0,
        cellPixels.toDouble(),
        cellPixels.toDouble(),
      );
    }).toList();
  }

  final double pixelRatio;
  late final int cellPixels;
  late final ui.Image image;
  late final List<Rect> cells;

  void dispose() => image.dispose();
}

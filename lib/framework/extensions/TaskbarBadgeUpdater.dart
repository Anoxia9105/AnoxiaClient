import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:windows_taskbar/windows_taskbar.dart';

class TaskbarBadgeUpdater {
  static int? _lastCount;

  static const MethodChannel _channel = MethodChannel(
    'com.alexmercerind/windows_taskbar',
  );

  static Future<void> updateBadge(int count) async {
    if (count == _lastCount) return;
    _lastCount = count;

    if (count <= 0) {
      await WindowsTaskbar.resetOverlayIcon();
      return;
    }

    try {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final double pixelRatio = view.devicePixelRatio;

      final double renderSize = 32.0;
      final double targetSize = 16.0;

      final ui.Image badgeImage = await _drawBadgeImage(
        count,
        renderSize,
        pixelRatio,
      );

      // 转为字节流
      final byteData = await badgeImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return;

      // 转为 image 库的 Image 对象
      var rawImage = img.Image.fromBytes(
        width: badgeImage.width,
        height: badgeImage.height,
        bytes: byteData.buffer,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );

      // 🔥 使用高质量算法缩小到 16×16
      final int targetWidth = (targetSize * (badgeImage.width / renderSize))
          .toInt();
      final int targetHeight = targetSize.toInt();

      rawImage = img.copyResize(
        rawImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.average, // 🔥 高质量插值
      );

      // 编码为 ICO
      final icoBytes = img.encodeIco(rawImage);

      // 写入临时文件
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/taskbar_badge.ico');
      await file.writeAsBytes(icoBytes, flush: true);

      await _channel.invokeMethod('SetOverlayIcon', {
        'icon': file.path,
        'tooltip': count > 99 ? '99+ 条未读' : '$count 条未读',
      });
    } catch (e) {
      debugPrint("任务栏角标更新失败: $e");
    }
  }

  /// 绘制高分辨率角标，后续会缩小
  static Future<ui.Image> _drawBadgeImage(
    int count,
    double size,
    double pixelRatio,
  ) async {
    final recorder = ui.PictureRecorder();

    // 动态宽度（胶囊形）
    double width = size;
    if (count > 99) {
      width = size * 1.35;
    } else if (count > 9) {
      width = size * 1.15;
    }

    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, size));

    // 🔥 添加轻微阴影增强对比度
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, width, size),
        Radius.circular(size / 2),
      ),
      shadowPaint,
    );

    // 背景
    final paint = Paint()
      ..color =
          const Color(0xFFD93025) // 🔥 更鲜艳的红色
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, size),
        Radius.circular(size / 2),
      ),
      paint,
    );

    // 文字内容
    String text = count > 99 ? "99+" : count.toString();

    // 🔥 字体大小优化
    double fontSize;
    if (count <= 9) {
      fontSize = size * 0.68;
    } else if (count <= 99) {
      fontSize = size * 0.58;
    } else {
      fontSize = size * 0.50;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          fontFamily: 'Segoe UI',
          height: 1.0,
          letterSpacing: count > 9 ? -1.0 : 0, // 🔥 多位数更紧凑
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // 绘制到画布中心
    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (size - textPainter.height) / 2 - 1, // 🔥 微调垂直居中
      ),
    );

    final picture = recorder.endRecording();
    return await picture.toImage(width.toInt(), size.toInt());
  }
}

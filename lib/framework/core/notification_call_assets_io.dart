import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;

/// 为系统通知生成本地 PNG：按钮图标使用白色透明底，头像缺失时使用姓名首字。
class NotificationCallAssets {
  NotificationCallAssets(this.directory);
  final Directory directory;

  Future<Uri> avatar(String name) async {
    final initial = name.trim().characters.firstOrNull ?? '?';
    final hash = sha256.convert(utf8.encode(initial)).toString();
    final file = File(
      '${directory.path}/notification_avatar_initial_$hash.png',
    );
    if (!await file.exists()) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 160, 160),
          const Radius.circular(12),
        ),
        Paint()..color = const Color(0xFF00695C),
      );
      final text = TextPainter(
        text: TextSpan(
          text: initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontFamily: 'NotoSansSC',
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 160);
      text.paint(
        canvas,
        Offset((160 - text.width) / 2, (160 - text.height) / 2),
      );
      text.dispose();
      await _write(recorder, file, 160);
    }
    return Uri.file(file.path, windows: true);
  }

  Future<Uri> icon(String name, List<List<dynamic>> icon) async {
    // 升级缓存名，避免沿用旧 Material 字体图标。
    final file = File(
      '${directory.path}/notification_call_${name}_huge_v2.png',
    );
    if (!await file.exists()) {
      final source = StringBuffer(
        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">',
      );
      const attributes = {
        'strokeWidth': 'stroke-width',
        'strokeLinecap': 'stroke-linecap',
        'strokeLinejoin': 'stroke-linejoin',
        'fillRule': 'fill-rule',
        'clipRule': 'clip-rule',
      };
      for (final element in icon) {
        source.write('<${element[0]}');
        for (final entry in (element[1] as Map<String, dynamic>).entries) {
          if (entry.key == 'key') continue;
          final value = entry.value == 'currentColor'
              ? '#ffffff'
              : entry.value.toString();
          source.write(
            ' ${attributes[entry.key] ?? entry.key}="${const HtmlEscape().convert(value)}"',
          );
        }
        source.write('/>');
      }
      source.write('</svg>');
      final picture = await svg.vg.loadPicture(
        svg.SvgStringLoader(source.toString()),
        null,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(32 / 24);
      canvas.drawPicture(picture.picture);
      try {
        await _write(recorder, file, 32);
      } finally {
        picture.picture.dispose();
      }
    }
    return Uri.file(file.path, windows: true);
  }

  Future<void> _write(ui.PictureRecorder recorder, File file, int size) async {
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    picture.dispose();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  }
}

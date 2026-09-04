import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

enum NoteImageUploadStatus { uploading, failed }

class NoteImageUploadState {
  const NoteImageUploadState(this.status, {this.progress = 0});

  final NoteImageUploadStatus status;
  final double progress;
}

class NoteImageUploadStore extends ChangeNotifier {
  final Map<String, NoteImageUploadState> _entries = {};

  NoteImageUploadState? operator [](String? id) => _entries[id];

  void uploading(String id, [double progress = 0]) {
    _entries[id] = NoteImageUploadState(
      NoteImageUploadStatus.uploading,
      progress: progress.clamp(0, 1),
    );
    notifyListeners();
  }

  void failed(String id) {
    _entries[id] = const NoteImageUploadState(NoteImageUploadStatus.failed);
    notifyListeners();
  }

  void complete(String id) {
    if (_entries.remove(id) != null) notifyListeners();
  }
}

final noteImageUploadStore = NoteImageUploadStore();

Map<String, dynamic> decodeNoteImageData(dynamic raw) {
  if (raw is! String) {
    return raw is Map ? Map<String, dynamic>.from(raw) : {};
  }
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
  } catch (_) {
    return raw.isEmpty ? {} : {'url': raw};
  }
}

bool updateNoteImageEmbed(
  QuillController controller,
  String imageId,
  Map<String, dynamic> changes,
) {
  var offset = 0;
  for (final operation in controller.document.toDelta().toList()) {
    final data = operation.data;
    if (data is Map && data[BlockEmbed.imageType] != null) {
      final image = decodeNoteImageData(data[BlockEmbed.imageType]);
      if (image['id'] == imageId) {
        controller.replaceText(
          offset,
          1,
          BlockEmbed(BlockEmbed.imageType, jsonEncode({...image, ...changes})),
          controller.selection,
        );
        return true;
      }
    }
    offset += operation.length ?? 0;
  }
  return false;
}

void updateNoteImageAtOffset(
  QuillController controller,
  int offset,
  Map<String, dynamic> image,
) {
  controller.replaceText(
    offset,
    1,
    BlockEmbed(BlockEmbed.imageType, jsonEncode(image)),
    controller.selection,
  );
}

/// 图片未知尺寸时的占位大小（仅在拿不到真实尺寸时使用）。
const double noteImageFallbackWidth = 320;
const double noteImageFallbackHeight = 220;

/// 手动拖动缩放的最小宽度，高度按宽高比联动。
const double noteImageMinWidth = 120;

bool _isValidDimension(double? value) => value != null && value > 0;

/// 从图片字节解码自然尺寸，失败返回 (null, null)。
Future<(double?, double?)> decodeNoteImageBytesSize(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = (image.width.toDouble(), image.height.toDouble());
    image.dispose();
    codec.dispose();
    if (!_isValidDimension(size.$1) || !_isValidDimension(size.$2)) {
      return (null, null);
    }
    return size;
  } catch (_) {
    return (null, null);
  }
}

/// 计算图片在编辑器内的自适应显示尺寸（等比、只缩小不放大）。
///
/// 优先级：用户已存尺寸（拖动结果）＞ 图片自然尺寸 ＞ 占位尺寸。
/// 存量笔记可能没有宽高，此时靠 [intrinsicWidth]/[intrinsicHeight]
///（展示层从 ImageProvider 回调拿到）来自适应。
Size resolveNoteImageDisplaySize({
  double? storedWidth,
  double? storedHeight,
  double? intrinsicWidth,
  double? intrinsicHeight,
  required double maxWidth,
}) {
  double? width = _isValidDimension(storedWidth) &&
          _isValidDimension(storedHeight)
      ? storedWidth
      : null;
  double? height = width == null ? null : storedHeight;
  if (width == null || height == null) {
    width = _isValidDimension(intrinsicWidth) &&
            _isValidDimension(intrinsicHeight)
        ? intrinsicWidth
        : null;
    height = width == null ? null : intrinsicHeight;
  }
  if (width == null || height == null) {
    width = noteImageFallbackWidth;
    height = noteImageFallbackHeight;
  }
  // 只缩小不放大：小图按原尺寸展示，避免拉伸模糊。
  final scale = math.min(1.0, maxWidth / width);
  return Size(width * scale, height * scale);
}

/// 右下角手柄拖动缩放：以宽度为基准等比缩放，高度按原宽高比联动。
///
/// 调用方应把横向与纵向位移合并后传入 [horizontalDelta]，
/// 保证任意方向拖动手柄都只做等比缩放。
(double, double) noteImageResize(
  double width,
  double height,
  double horizontalDelta, {
  required double maxWidth,
}) {
  final safeWidth = width <= 0 ? noteImageFallbackWidth : width;
  final safeHeight = height <= 0 ? noteImageFallbackHeight : height;
  // 极窄编辑器下限取 maxWidth，避免 clamp 越界抛错。
  final lower = maxWidth < noteImageMinWidth ? maxWidth : noteImageMinWidth;
  final nextWidth = (safeWidth + horizontalDelta).clamp(lower, maxWidth);
  return (nextWidth, nextWidth * safeHeight / safeWidth);
}

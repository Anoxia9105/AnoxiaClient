import 'dart:convert';

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

(double, double) noteImageResize(
  double width,
  double height,
  double horizontalDelta, {
  required double maxWidth,
}) {
  final safeWidth = width <= 0 ? 320.0 : width;
  final safeHeight = height <= 0 ? 180.0 : height;
  final nextWidth = (safeWidth + horizontalDelta).clamp(120.0, maxWidth);
  return (nextWidth, nextWidth * safeHeight / safeWidth);
}

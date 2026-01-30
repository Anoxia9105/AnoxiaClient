import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class QuillEmbedUtil {
  static void insertEmbed({
    required QuillController controller,
    required String type,
    required Map<String, dynamic> data,
  }) {
    final offset = controller.selection.baseOffset;
    if (offset < 0) return;

    controller.replaceText(
      offset,
      0,
      BlockEmbed(type, jsonEncode(data)),
      TextSelection.collapsed(offset: offset + 1),
    );
  }

  /// 插入文本
  static void insertTextAtCursor({
    required QuillController controller,
    required String text,
  }) {
    final offset = controller.selection.baseOffset;
    if (offset < 0) return;
    controller.replaceText(
      offset,
      0,
      text,
      TextSelection.collapsed(offset: offset + text.length),
    );
  }
}

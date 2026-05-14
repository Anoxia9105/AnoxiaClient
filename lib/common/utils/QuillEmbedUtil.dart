import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Quill 富文本编辑器嵌入工具
///
/// 提供在 Quill 编辑器中插入嵌入元素（如图片）和文本的辅助方法。
class QuillEmbedUtil {
  /// 插入嵌入元素
  ///
  /// 在当前光标位置插入指定类型的嵌入内容
  ///
  /// [controller] Quill 编辑器控制器
  /// [type] 嵌入类型标识
  /// [data] 嵌入数据（如图片 URL）
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

  /// 在光标位置插入文本
  ///
  /// [controller] Quill 编辑器控制器
  /// [text] 要插入的文本内容
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

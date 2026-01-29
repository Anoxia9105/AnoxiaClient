import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../logs/talker.dart';

extension QuillEditorX on GlobalKey<QuillEditorState> {
  /// 安全获取当前光标在屏幕上的全局坐标
  Offset? getCaretClientPosition() {
    final editorState = currentState;
    if (editorState == null) return null;

    // 1. 获取内部 RenderEditor
    final renderEditor = editorState.editableTextKey.currentState?.renderEditor;
    if (renderEditor == null) return null;

    // 2. 获取当前选中范围
    final selection = editorState.widget.controller.selection;
    if (!selection.isValid) return null;

    try {
      // 3. 计算光标矩形并转换为全局坐标
      final caretRect = renderEditor.getLocalRectForCaret(
        TextPosition(offset: selection.baseOffset),
      );
      final offset = renderEditor.localToGlobal(caretRect.topRight);
      return offset;
    } catch (e) {
      log.error("获取光标坐标失败: $e");
      return null;
    }
  }
}

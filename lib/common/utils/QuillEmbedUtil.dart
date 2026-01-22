import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class QuillEmbedUtil {
  static void insertEmber({
    required QuillController controller,
    required String type,
    required Map<String, String> data,
  }) {
    final offset = controller.selection.baseOffset;
    if (offset < 0) return;
    final embed = BlockEmbed(type, jsonEncode(data));
    controller.replaceText(
      offset,
      0,
      embed,
      TextSelection.collapsed(offset: offset + 1),
    );
  }
  ///
  /// @ 删除用户输入@符号
  void deleteEmbedAtCursor(QuillController controller) {
    final offset = controller.selection.baseOffset;
    if (offset < 0) return;
    controller.replaceText(
      offset - 1,
      1,
      '',
      TextSelection.collapsed(offset: offset),
    );
  }
  // void setupAtMentionListener() {
  //   _controller.document.changes.listen((event) {
  //     final selection = _controller.selection;
  //     // 光标未聚焦或无效时不处理
  //     if (!selection.isValid || !selection.isCollapsed) return;
  //
  //     final offset = selection.baseOffset;
  //     final plainText = _controller.document.toPlainText();
  //
  //     if (offset <= 0 || offset > plainText.length) return;
  //
  //     final beforeCursor = plainText.substring(0, offset);
  //     int atIndex = beforeCursor.lastIndexOf('@');
  //
  //     if (atIndex == -1) {
  //       // 没有@符号，只隐藏建议框，但光标保持正常
  //       if (showAtSuggestion || currentMentionKeyword.isNotEmpty) {
  //         showAtSuggestion = true;
  //         currentMentionKeyword = '';
  //         WidgetsBinding.instance.addPostFrameCallback((_) {
  //           notifyListeners();
  //         });
  //       }
  //       return;
  //     }
  //
  //     final keyword = beforeCursor.substring(atIndex + 1);
  //     if (keyword.isNotEmpty && !showAtSuggestion) {
  //       return;
  //     }
  //     // 含非法字符（空格、标点等） 或者 长度过长，视为非法
  //     final illegal =
  //         keyword.contains(RegExp(r'[^\u4e00-\u9fa5\w]')) ||
  //             keyword.length > 20;
  //     if (illegal || keyword.isEmpty) {
  //       showAtSuggestion = true;
  //       currentMentionKeyword = '';
  //       WidgetsBinding.instance.addPostFrameCallback((_) {
  //         notifyListeners();
  //       });
  //       return;
  //     }
  //
  //     // 如果有@ 但是已经关闭了  不显示框子 可以直接删除关键字
  //
  //     // 一切正常
  //     showAtSuggestion = true;
  //     currentMentionKeyword = keyword;
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       notifyListeners();
  //     });
  //   });
  // }
}

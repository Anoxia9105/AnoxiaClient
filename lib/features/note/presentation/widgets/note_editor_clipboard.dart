// ignore_for_file: experimental_member_use

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';

enum NotePasteResult { image, richText, unhandled }

/// 记事本粘贴路由：与聊天输入框一致优先识别图片，其余内容交还 Quill。
///
/// Quill 自己维护同一控制器内复制的 Delta，并通过原生桥读取外部 HTML；
/// 因此非图片内容不能降级为手工 `replaceText`，否则会丢失行内式样。
Future<NotePasteResult> handleNoteEditorPaste({
  required Future<Uint8List?> Function() readImage,
  required Future<void> Function(Uint8List bytes) pasteImage,
  required Future<bool> Function() pasteRichText,
}) async {
  try {
    final imageBytes = await readImage();
    if (imageBytes != null && imageBytes.isNotEmpty) {
      await pasteImage(imageBytes);
      return NotePasteResult.image;
    }
  } catch (_) {
    // 某些平台不支持读取图片剪贴板，继续走 Quill 富文本粘贴。
  }

  return await pasteRichText()
      ? NotePasteResult.richText
      : NotePasteResult.unhandled;
}

/// 把 Web `paste` 事件携带的 HTML 转为 Delta 并替换当前选区。
bool pasteNoteEditorHtml(
  QuillController controller,
  String html, {
  String plainTextFallback = '',
}) {
  if (html.trim().isEmpty) return false;

  late final Delta delta;
  try {
    delta = HtmlToDelta().convert(html);
  } catch (_) {
    return pasteNoteEditorPlainText(controller, plainTextFallback);
  }
  if (delta.isEmpty || (delta.length == 1 && delta.first.data == '\n')) {
    return pasteNoteEditorPlainText(controller, plainTextFallback);
  }

  final selection = controller.selection;
  final start = selection.isValid
      ? selection.start
      : controller.document.length - 1;
  final replacedLength = selection.isValid && !selection.isCollapsed
      ? selection.end - selection.start
      : 0;
  controller.replaceText(
    start,
    replacedLength,
    delta,
    TextSelection.collapsed(offset: start + delta.length),
  );
  return true;
}

bool pasteNoteEditorPlainText(QuillController controller, String text) {
  if (text.isEmpty) return false;
  final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final selection = controller.selection;
  final start = selection.isValid
      ? selection.start
      : controller.document.length - 1;
  final replacedLength = selection.isValid && !selection.isCollapsed
      ? selection.end - selection.start
      : 0;
  final copiedDelta = controller.pasteDelta;
  final content =
      normalized == controller.pastePlainText &&
          controller.pastePlainText.isNotEmpty &&
          copiedDelta.isNotEmpty
      ? copiedDelta
      : normalized;
  controller.replaceText(
    start,
    replacedLength,
    content,
    TextSelection.collapsed(offset: start + normalized.length),
  );
  return true;
}

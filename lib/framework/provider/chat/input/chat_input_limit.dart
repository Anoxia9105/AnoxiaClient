// 聊天输入框字符限制工具。
//
// 为 Quill 聊天编辑器提供统一的字符数计算和粘贴限制检查。
import 'package:flutter_quill/flutter_quill.dart';

/// Central limits for every Quill chat composer.
abstract final class ChatInputLimit {
  /// 最大字符数限制。
  static const int maxCharacters = 20000;

  /// 计算当前编辑器的字符数。
  ///
  /// 扣除 Quill 文档末尾的终止换行符。
  static int currentLength(QuillController controller) {
    // Quill documents always include one terminal newline.
    return (controller.document.length - 1).clamp(0, maxCharacters + 1);
  }

  /// 计算粘贴操作可用的剩余字符数。
  ///
  /// 考虑当前选中内容的替换，选中内容会被新文本覆盖。
  static int remainingForPaste(QuillController controller) {
    final selection = controller.selection;
    final selectedLength = selection.isValid
        ? selection.end - selection.start
        : 0;
    return (maxCharacters - currentLength(controller) + selectedLength).clamp(
      0,
      maxCharacters,
    );
  }

  /// 检查指定文本是否可以粘贴到编辑器中。
  static bool canPaste(QuillController controller, String text) {
    return text.length <= remainingForPaste(controller);
  }
}

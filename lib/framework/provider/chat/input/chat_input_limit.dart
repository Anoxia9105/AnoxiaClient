import 'package:flutter_quill/flutter_quill.dart';

/// Central limits for every Quill chat composer.
abstract final class ChatInputLimit {
  static const int maxCharacters = 20000;

  static int currentLength(QuillController controller) {
    // Quill documents always include one terminal newline.
    return (controller.document.length - 1).clamp(0, maxCharacters + 1);
  }

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

  static bool canPaste(QuillController controller, String text) {
    return text.length <= remainingForPaste(controller);
  }
}

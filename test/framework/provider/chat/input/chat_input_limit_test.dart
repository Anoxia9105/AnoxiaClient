import 'package:anoxia/framework/provider/chat/input/chat_input_limit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects paste larger than the remaining character capacity', () {
    final controller = QuillController(
      document: Document()..insert(0, 'a' * 19999),
      selection: const TextSelection.collapsed(offset: 19999),
    );
    addTearDown(controller.dispose);

    expect(ChatInputLimit.remainingForPaste(controller), 1);
    expect(ChatInputLimit.canPaste(controller, 'b'), isTrue);
    expect(ChatInputLimit.canPaste(controller, 'bc'), isFalse);
  });

  test('selected text is deducted when calculating paste capacity', () {
    final controller = QuillController(
      document: Document()..insert(0, 'a' * 20000),
      selection: const TextSelection(baseOffset: 100, extentOffset: 200),
    );
    addTearDown(controller.dispose);

    expect(ChatInputLimit.remainingForPaste(controller), 100);
    expect(ChatInputLimit.canPaste(controller, 'b' * 100), isTrue);
    expect(ChatInputLimit.canPaste(controller, 'b' * 101), isFalse);
  });
}

// ChatInputLimit（输入框字符限制）单元测试。
//
// 锁定 20000 字符上限与粘贴剩余额度（含选中替换）的计算口径。
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_limit.dart';
import 'package:flutter_test/flutter_test.dart';

QuillController controllerWith(String text) {
  final controller = QuillController.basic();
  if (text.isNotEmpty) {
    controller.document.insert(0, text);
  }
  return controller;
}

void main() {
  group('currentLength', () {
    test('空编辑器为 0（扣除终止换行）', () {
      expect(ChatInputLimit.currentLength(controllerWith('')), 0);
    });

    test('计入普通文本长度', () {
      expect(ChatInputLimit.currentLength(controllerWith('hello')), 5);
    });
  });

  group('remainingForPaste', () {
    test('空编辑器剩余额度 = maxCharacters', () {
      expect(ChatInputLimit.remainingForPaste(controllerWith('')), ChatInputLimit.maxCharacters);
    });

    test('已有内容按长度扣减', () {
      expect(
        ChatInputLimit.remainingForPaste(controllerWith('hello')),
        ChatInputLimit.maxCharacters - 5,
      );
    });

    test('选区会被新文本覆盖，剩余额度相应放大', () {
      final controller = controllerWith('hello');
      // 选中 "ell"（offset 1..4）
      final sel = const TextSelection(baseOffset: 1, extentOffset: 4);
      controller.updateSelection(sel, ChangeSource.local);
      expect(
        ChatInputLimit.remainingForPaste(controller),
        ChatInputLimit.maxCharacters - 5 + 3,
      );
    });
  });

  group('canPaste', () {
    const filler = 'x';
    test('恰好等于剩余额度的粘贴允许', () {
      final controller = controllerWith('');
      expect(
        ChatInputLimit.canPaste(controller, filler * ChatInputLimit.maxCharacters),
        isTrue,
      );
    });

    test('超过剩余额度一个字符即拒绝', () {
      final controller = controllerWith('');
      expect(
        ChatInputLimit.canPaste(
          controller,
          filler * (ChatInputLimit.maxCharacters + 1),
        ),
        isFalse,
      );
    });

    test('已有内容后同样精确到字符', () {
      final controller = controllerWith('hello');
      expect(
        ChatInputLimit.canPaste(controller, filler * (ChatInputLimit.maxCharacters - 5)),
        isTrue,
      );
      expect(
        ChatInputLimit.canPaste(controller, filler * (ChatInputLimit.maxCharacters - 4)),
        isFalse,
      );
    });
  });
}

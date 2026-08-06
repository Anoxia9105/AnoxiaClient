import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_code_line_number.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_style_config.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_syntax_highlighter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

QuillController _codeBlockController() {
  return QuillController(
    document: Document.fromJson(const [
      {'insert': 'hello\n'},
      {
        'insert': 'print(1)\n',
        'attributes': {'code-block': 'python'},
      },
      {
        'insert': 'print(2)\n',
        'attributes': {'code-block': 'python'},
      },
      {'insert': '\n'},
    ]),
    selection: const TextSelection.collapsed(offset: 7),
  );
}

void main() {
  Future<void> pumpEditor(
    WidgetTester tester,
    QuillController controller, {
    int? seed,
  }) async {
    final focusNode = FocusNode();
    addTearDown(() {
      controller.dispose();
      focusNode.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: seed == null
            ? ThemeData(colorSchemeSeed: Colors.blue)
            : ThemeData(colorSchemeSeed: Color(seed)),
        home: Scaffold(
          body: Builder(
            builder: (context) => QuillEditor.basic(
              controller: controller,
              focusNode: focusNode,
              config: QuillEditorConfig(
                enableSelectionToolbar: false,
                placeholder: 'chat_input_placeholder',
                autoFocus: false,
                padding: const EdgeInsets.all(8),
                customStyles: QuillStyleConfig.get(context),
                textSpanBuilder: QuillSyntaxHighlighter.buildSpan,
                customLeadingBlockBuilder: (node, config) =>
                    QuillCodeLineNumber.build(
                  node,
                  config,
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> paste(WidgetTester tester, String text, int offset) async {
    final controller = (tester.widget<QuillEditor>(find.byType(QuillEditor)))
        .controller;
    final sel = controller.selection;
    final start = offset;
    controller.replaceText(
      start,
      sel.isCollapsed ? 0 : sel.end - sel.start,
      text,
      TextSelection.collapsed(offset: start + text.length),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('A: paste mid-line inside code block (cursor at line start)',
      (tester) async {
    // 光标在代码块第一行开头 (offset 7)
    final controller = _codeBlockController();
    await pumpEditor(tester, controller);
    await paste(tester, 'x = 1\ny = 2\n', 7);
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('A delta: ${controller.document.toDelta().toJson()}');
  });

  testWidgets('B: paste replacing multi-line selection inside code block',
      (tester) async {
    final controller = QuillController(
      document: Document.fromJson(const [
        {'insert': 'hello\n'},
        {
          'insert': 'print(1)\n',
          'attributes': {'code-block': 'python'},
        },
        {
          'insert': 'print(2)\n',
          'attributes': {'code-block': 'python'},
        },
        {'insert': '\n'},
      ]),
      // 选中代码块第一行整行 + 第二行开头
      selection: const TextSelection(baseOffset: 7, extentOffset: 14),
    );
    await pumpEditor(tester, controller);
    final text = 'a = 1\nb = 2\n';
    final sel = controller.selection;
    controller.replaceText(
      sel.start,
      sel.end - sel.start,
      text,
      TextSelection.collapsed(offset: sel.start + text.length),
    );
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('B delta: ${controller.document.toDelta().toJson()}');
  });

  testWidgets('C: paste at very end of last code line', (tester) async {
    final controller = _codeBlockController();
    await pumpEditor(tester, controller);
    // 光标在第二行代码末尾：'print(2)' 的 offset
    await paste(tester, 'tail\nmore\n', 20);
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('C delta: ${controller.document.toDelta().toJson()}');
  });
}

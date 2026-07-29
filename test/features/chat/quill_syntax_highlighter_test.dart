import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_code_line_number.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_style_config.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_syntax_highlighter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders editable block and inline code with syntax spans', (
    tester,
  ) async {
    final controller = QuillController(
      document: Document.fromJson([
        {'insert': 'final value = 42;'},
        {
          'insert': '\n',
          'attributes': {'code-block': true},
        },
        {
          'insert': 'value',
          'attributes': {'code': true},
        },
        {'insert': '\n'},
      ]),
      selection: const TextSelection.collapsed(offset: 0),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => QuillEditor.basic(
              controller: controller,
              config: QuillEditorConfig(
                customStyles: QuillStyleConfig.get(context),
                textSpanBuilder: QuillSyntaxHighlighter.buildSpan,
                // ignore: experimental_member_use
                customLeadingBlockBuilder: QuillCodeLineNumber.build,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(QuillEditor), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders incomplete punctuation-only code without exceptions', (
    tester,
  ) async {
    final controller = QuillController(
      document: Document.fromJson([
        {'insert': '^'},
        {
          'insert': '\n',
          'attributes': {'code-block': true},
        },
        {'insert': '='},
        {
          'insert': '\n',
          'attributes': {'code-block': true},
        },
      ]),
      selection: const TextSelection.collapsed(offset: 0),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => QuillEditor.basic(
              controller: controller,
              config: QuillEditorConfig(
                customStyles: QuillStyleConfig.get(context),
                textSpanBuilder: QuillSyntaxHighlighter.buildSpan,
                // ignore: experimental_member_use
                customLeadingBlockBuilder: QuillCodeLineNumber.build,
              ),
            ),
          ),
        ),
      ),
    );

    expect(controller.document.toPlainText(), '^\n=\n');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

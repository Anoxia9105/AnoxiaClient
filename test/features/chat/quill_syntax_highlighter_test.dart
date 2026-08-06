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
        {
          'insert': 'final value = 42;\n',
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

    expect(find.byType(QuillEditor), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders incomplete punctuation-only code without exceptions', (
    tester,
  ) async {
    final controller = QuillController(
      document: Document.fromJson([
        {
          'insert': '^\n',
          'attributes': {'code-block': true},
        },
        {
          'insert': '=\n',
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

    expect(controller.document.toPlainText(), '^\n=\n');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    final firstCodeText = find.byWidgetPredicate(
      (widget) =>
          widget is RichText &&
          widget.text.toPlainText(includeSemanticsLabels: false) == '^',
    );
    final lineNumberRect = tester.getRect(find.text('1'));
    final lineNumberGutter = find
        .ancestor(of: find.text('1'), matching: find.byType(Container))
        .first;
    final gutterRect = tester.getRect(lineNumberGutter);
    final codeTextRect = tester.getRect(firstCodeText);
    expect(lineNumberRect.right, lessThanOrEqualTo(codeTextRect.left));
    expect(gutterRect.width, QuillCodeLineNumber.gutterWidth);
    expect(lineNumberRect.left, gutterRect.left);
    expect(gutterRect.right, lessThanOrEqualTo(codeTextRect.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('language badge updates the code block language attribute', (
    tester,
  ) async {
    final controller = QuillController(
      document: Document.fromJson([
        {
          'insert': '@override Widget build() {}\n',
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
    await tester.pump();

    expect(find.text('Dart'), findsOneWidget);
    await tester.tap(find.text('Dart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Python').last);
    await tester.pumpAndSettle();

    final operations = controller.document.toDelta().toJson();
    expect(operations.last['attributes']?['code-block'], 'python');
    expect(find.text('Python'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

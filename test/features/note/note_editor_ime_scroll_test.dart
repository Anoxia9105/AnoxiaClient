import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('外层滚动会同步改变编辑器屏幕变换供 IME 定位', (tester) async {
    final document = Document()
      ..insert(0, List.generate(40, (index) => 'line $index').join('\n'));
    final controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    final focusNode = FocusNode();
    final scrollController = ScrollController();
    final editorKey = GlobalKey<EditorState>();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 120,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: QuillEditor.basic(
                      controller: controller,
                      focusNode: focusNode,
                      scrollController: scrollController,
                      config: QuillEditorConfig(
                        scrollable: false,
                        editorKey: editorKey,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderEditor = editorKey.currentState!.renderEditor;
    final caretRect = renderEditor.getLocalRectForCaret(
      const TextPosition(offset: 0),
    );
    final before = renderEditor.localToGlobal(caretRect.topLeft);

    scrollController.jumpTo(80);
    await tester.pump();

    final after = renderEditor.localToGlobal(caretRect.topLeft);
    expect(after.dy, closeTo(before.dy - 80, 0.5));
  });
}

import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_quill_toggle_style_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  testWidgets('点击格式按钮后恢复编辑器焦点并应用到后续输入', (tester) async {
    final controller = QuillController.basic();
    final editorFocusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(editorFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ChatQuillToggleStyleButton(
                controller: controller,
                focusNode: editorFocusNode,
                icon: HugeIcons.strokeRoundedTextBold,
                attribute: Attribute.bold,
                tooltip: '加粗',
              ),
              Expanded(
                child: QuillEditor.basic(
                  controller: controller,
                  focusNode: editorFocusNode,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('加粗'));
    await tester.pump();

    expect(editorFocusNode.hasFocus, isTrue);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).isSelected,
      isTrue,
    );
    expect(tester.widget<HugeIcon>(find.byType(HugeIcon)).strokeWidth, 2.5);

    controller.replaceText(0, 0, 'A', const TextSelection.collapsed(offset: 1));

    expect(
      controller.document.collectStyle(0, 1).attributes,
      containsPair(Attribute.bold.key, Attribute.bold),
    );
  });

  testWidgets('按钮激活态跟随光标所在文字的格式', (tester) async {
    final controller = QuillController(
      document: Document.fromJson(const [
        {
          'insert': '粗体',
          'attributes': {'bold': true},
        },
        {'insert': '普通\n'},
      ]),
      selection: const TextSelection.collapsed(offset: 3),
    );
    final editorFocusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(editorFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatQuillToggleStyleButton(
            controller: controller,
            focusNode: editorFocusNode,
            icon: HugeIcons.strokeRoundedTextBold,
            attribute: Attribute.bold,
            tooltip: '加粗',
          ),
        ),
      ),
    );

    expect(
      tester.widget<IconButton>(find.byType(IconButton)).isSelected,
      isFalse,
    );
    expect(tester.widget<HugeIcon>(find.byType(HugeIcon)).strokeWidth, 1.5);

    controller.updateSelection(
      const TextSelection.collapsed(offset: 1),
      ChangeSource.local,
    );
    await tester.pump();

    expect(
      tester.widget<IconButton>(find.byType(IconButton)).isSelected,
      isTrue,
    );
    expect(tester.widget<HugeIcon>(find.byType(HugeIcon)).strokeWidth, 2.5);

    controller.updateSelection(
      const TextSelection.collapsed(offset: 3),
      ChangeSource.local,
    );
    await tester.pump();

    expect(
      tester.widget<IconButton>(find.byType(IconButton)).isSelected,
      isFalse,
    );
  });
}

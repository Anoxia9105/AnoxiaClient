import 'package:anoxia/framework/provider/chat/input/mobile_text_input_controller.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> buildField(
    WidgetTester tester,
    MobileTextInputController controller,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(controller: controller.textController),
        ),
      ),
    );
  }

  // 模拟用户在输入框内输入后的状态：真实流程中 TextField 先把新文本写进
  // textController，再回调 handleTextChanged。
  void setText(
    MobileTextInputController controller,
    String text, {
    int? cursor,
  }) {
    final offset = cursor ?? text.length;
    controller.textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
    controller.handleTextChanged(text);
  }

  List<TextSpan> flattenSpans(List<InlineSpan>? spans) {
    final out = <TextSpan>[];
    if (spans == null) return out;
    for (final span in spans) {
      if (span is TextSpan) {
        out.add(span);
        out.addAll(flattenSpans(span.children));
      }
    }
    return out;
  }

  List<TextSpan> rootSpans(
    WidgetTester tester,
    MobileTextInputController controller,
  ) {
    final context = tester.element(find.byType(TextField));
    return flattenSpans(
      [
        controller.textController.buildTextSpan(
          context: context,
          style: const TextStyle(),
          withComposing: false,
        ),
      ],
    );
  }

  testWidgets('insertMention 后 buildTextSpan 渲染红色高亮区间', (tester) async {
    final controller = MobileTextInputController();
    addTearDown(controller.dispose);
    await buildField(tester, controller);

    setText(controller, 'Hi @');
    controller.insertMention(1, 'alice');

    expect(controller.textController.text, 'Hi @alice ');

    final mention = rootSpans(tester, controller).firstWhere(
      (s) => s.text == '@alice',
    );
    expect(mention.style?.color, Colors.red);
    expect(mention.style?.fontWeight, FontWeight.bold);
    expect(
      mention.style?.backgroundColor,
      Colors.red.withValues(alpha: 0.1),
    );

    final data = controller.buildSendData()!;
    expect(data.mentionIds, [1]);
  });

  testWidgets('在提及之后输入文本，高亮区间随文本整体位移', (tester) async {
    final controller = MobileTextInputController();
    addTearDown(controller.dispose);
    await buildField(tester, controller);

    setText(controller, '@alice ');
    controller.insertMention(1, 'alice');
    setText(controller, '@alice  hello', cursor: 14);
    await tester.pump();

    final mention = rootSpans(tester, controller).firstWhere(
      (s) => s.text == '@alice',
    );
    expect(mention.style?.backgroundColor, isNotNull);
  });

  testWidgets('在提及内部删除字符会取消高亮且不再发送', (tester) async {
    final controller = MobileTextInputController();
    addTearDown(controller.dispose);
    await buildField(tester, controller);

    setText(controller, 'Hi @alice ');
    controller.insertMention(1, 'alice');
    // 模拟用户删除 "ali"：提及被破坏，降级为普通文本。
    setText(controller, 'Hi @ce ');
    await tester.pump();

    expect(
      rootSpans(tester, controller).where(
        (s) => s.style?.backgroundColor != null,
      ),
      isEmpty,
    );
    expect(controller.buildSendData()?.text, 'Hi @ce');
    expect(controller.buildSendData()?.mentionIds, isEmpty);
  });

  testWidgets('在提及之前插入表情，提及区间随文本后移', (tester) async {
    final controller = MobileTextInputController();
    addTearDown(controller.dispose);
    await buildField(tester, controller);

    setText(controller, 'Hi @alice ');
    controller.insertMention(1, 'alice');
    controller.textController.selection = const TextSelection.collapsed(
      offset: 0,
    );
    controller.insertTextAtCursor('👋');

    expect(controller.textController.text, '👋Hi @alice ');
    final mention = rootSpans(tester, controller).firstWhere(
      (s) => s.text == '@alice',
    );
    expect(mention.style?.backgroundColor, isNotNull);
    expect(controller.buildSendData()!.mentionIds, [1]);
  });

  test('clear 重置文本与提及区间', () {
    final controller = MobileTextInputController();
    controller.handleTextChanged('Hi @alice ');
    controller.insertMention(1, 'alice');
    controller.clear();

    expect(controller.isEmpty, isTrue);
    expect(controller.textController.text, isEmpty);
    expect(controller.textController.mentions, isEmpty);
    expect(controller.buildSendData(), isNull);
  });

  testWidgets('insertMentionAll 插入 @所有人，发送时携带 mentionAll 且排除占位 ID', (tester) async {
    final controller = MobileTextInputController();
    addTearDown(controller.dispose);
    await buildField(tester, controller);

    setText(controller, 'Hi @');
    controller.insertMentionAll();

    expect(controller.textController.text, 'Hi @mention_all ');

    final data = controller.buildSendData()!;
    expect(data.mentionAll, isTrue);
    expect(data.mentionIds, isEmpty);
    expect(data.quillDelta, contains(kMentionAllUserId.toString()));
  });

  testWidgets('@所有人 与普通提及混用：mentionAll 为 true 且保留真实用户 ID', (tester) async {
    final controller = MobileTextInputController();
    addTearDown(controller.dispose);
    await buildField(tester, controller);

    setText(controller, 'Hi @');
    controller.insertMentionAll();
    controller.textController.selection = TextSelection.collapsed(
      offset: controller.textController.text.length,
    );
    controller.textController.value = TextEditingValue(
      text: '${controller.textController.text}@',
      selection: TextSelection.collapsed(
        offset: controller.textController.text.length + 1,
      ),
    );
    controller.handleTextChanged(controller.textController.text);
    controller.insertMention(2, 'bob');

    final data = controller.buildSendData()!;
    expect(data.mentionAll, isTrue);
    expect(data.mentionIds, [2]);
  });
}
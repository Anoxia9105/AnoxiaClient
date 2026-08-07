import 'dart:convert';

import 'package:anoxia/features/chat/presentation/widgets/message_render/quill_message_strategy.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('desktop 富文本含 code-block 渲染内容检查', (tester) async {
    final delta = [
      {'insert': 'hello\n'},
      {
        'insert': 'print(1)\n',
        'attributes': {'code-block': 'python'},
      },
      {'insert': '\n'},
    ];
    final message = ChatMessage(
      messageId: 'repro',
      messageType: MessageType.richText,
      content: '',
      payload: MessagePayload(content: '', quillDelta: jsonEncode(delta)),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Builder(
            builder: (context) => QuillMessageStrategy().buildContent(
              context,
              message,
              Colors.black,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    final rich = tester.widgetList(find.byType(RichText)).map(
          (w) => (w as RichText).text.toPlainText(),
        );
    debugPrint('RichText texts: $rich');
    final allTexts = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .toList();
    debugPrint('Text widgets data: $allTexts');
    expect(find.byType(RichText), findsWidgets);
  });
}

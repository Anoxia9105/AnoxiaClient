import 'dart:convert';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/quill_message_strategy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('render real strategy with mention + color', (tester) async {
    final delta = [
      {
        'insert': {
          'mention': '{"userId":123,"userName":"张三"}',
        },
      },
      {'insert': ' '},
      {'insert': '红色', 'attributes': {'color': '#FF0000'}},
      {'insert': '\n'},
    ];

    final message = ChatMessage(
      messageId: '1',
      messageType: MessageType.richText,
      content: '',
      payload: MessagePayload(
        content: '',
        quillDelta: jsonEncode(delta),
        mentions: [123],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => QuillMessageStrategy().buildContent(
                context,
                message,
                Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final ex = tester.takeException();
    if (ex != null) {
      // ignore: avoid_print
      print('EXCEPTION: $ex');
    }
    // ignore: avoid_print
    print('@张三 found: ${find.text('@张三').evaluate().length}');
    // ignore: avoid_print
    print('MESSAGE renderer: ${find.byType(QuillMessageStrategy).evaluate().length}');

    for (final w in tester.widgetList<RichText>(find.byType(RichText))) {
      // ignore: avoid_print
      print(
        'RICH: "${w.text.toPlainText(includeSemanticsLabels: false)}" color=${w.text.style?.color}',
      );
    }
  });
}
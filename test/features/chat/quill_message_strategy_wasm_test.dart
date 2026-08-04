import 'dart:convert';

import 'package:anoxia/features/chat/presentation/widgets/message_render/quill_message_strategy.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _isWasm = kIsWeb && !bool.fromEnvironment('dart.library.html');

void main() {
  testWidgets('WASM 富文本移除终止换行并保持 mention 同行', (tester) async {
    final message = _richTextMessage([
      {
        'insert': {
          'mention': jsonEncode({'userId': 3, 'userName': 'CC3'}),
        },
      },
      {'insert': ' 哈哈哈\n'},
    ]);

    await tester.pumpWidget(_testApp(message));
    await tester.pump();

    expect(find.text('@CC3'), findsOneWidget);
    final selectableFinder = find.byType(SelectableText);
    expect(selectableFinder, findsOneWidget);

    final selectable = tester.widget<SelectableText>(selectableFinder);
    expect(selectable.textSpan?.toPlainText().endsWith('\n'), isFalse);
    expect(tester.getSize(selectableFinder).height, lessThan(30));
  }, skip: !_isWasm);

  testWidgets('WASM 短富文本按实际内容宽度收缩', (tester) async {
    final message = _richTextMessage([
      {
        'insert': '111',
        'attributes': {'italic': true},
      },
      {'insert': '\n'},
    ]);

    await tester.pumpWidget(_testApp(message));
    await tester.pump();

    final size = tester.getSize(find.byType(SelectableText));
    expect(size.width, lessThan(48));
    expect(size.height, lessThan(30));
  }, skip: !_isWasm);

  testWidgets('WASM 单行消息最后一个字不换行', (tester) async {
    // 回归：DefaultTextStyle 携带 letterSpacing 时，气泡宽度必须包含字距，
    // 否则最后一个字被挤到第二行。
    final text = List.generate(28, (_) => '字').join();
    final message = _richTextMessage([
      {'insert': text},
      {'insert': '\n'},
    ]);

    await tester.pumpWidget(_testApp(message));
    await tester.pump();

    final selectable = find.byType(SelectableText);
    expect(selectable, findsOneWidget);
    final size = tester.getSize(selectable);
    // 单行应小于两行高度；高度超过一行即为换行。
    expect(size.height, lessThan(30));
  }, skip: !_isWasm);
}

Widget _testApp(ChatMessage message) {
  return MaterialApp(
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
  );
}

ChatMessage _richTextMessage(List<Map<String, dynamic>> delta) {
  return ChatMessage(
    messageId: 'wasm-render-test',
    messageType: MessageType.richText,
    content: '',
    payload: MessagePayload(content: '', quillDelta: jsonEncode(delta)),
  );
}

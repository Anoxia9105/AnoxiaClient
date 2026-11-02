import 'dart:convert';

import 'package:anoxia/features/chat/presentation/widgets/message_render/quill_message_strategy.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/text_message_strategy.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_bubble/message_selection_scope.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

ChatMessage richMessage(String text) => ChatMessage(
  messageId: text,
  messageType: MessageType.richText,
  payload: MessagePayload(
    quillDelta: jsonEncode([
      {'insert': '$text\n'},
    ]),
  ),
);

Future<void> dragText(WidgetTester tester, Finder target) async {
  final rect = tester.getRect(target);
  final mouse = await tester.startGesture(
    rect.topLeft + const Offset(2, 10),
    kind: PointerDeviceKind.mouse,
  );
  await mouse.moveBy(const Offset(80, 0));
  await tester.pump();
  await mouse.moveBy(const Offset(30, 0));
  await mouse.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('鼠标依次拖动两条 Quill 消息只保留当前选区', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        localizationsDelegates: const [FlutterQuillLocalizations.delegate],
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuillMessageStrategy().buildContent(
                  context,
                  richMessage('first message text'),
                  Colors.black,
                ),
                const SizedBox(height: 32),
                QuillMessageStrategy().buildContent(
                  context,
                  richMessage('second message text'),
                  Colors.black,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final editors = tester
        .widgetList<QuillEditor>(find.byType(QuillEditor))
        .toList();
    await dragText(tester, find.byType(QuillEditor).at(0));
    expect(editors[0].controller.selection.isCollapsed, isFalse);
    await dragText(tester, find.byType(QuillEditor).at(1));
    expect(editors[0].controller.selection.isCollapsed, isTrue);
    expect(editors[1].controller.selection.isCollapsed, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('普通文字支持鼠标拖动选择', (tester) async {
    final handle = MessageSelectionHandle();
    addTearDown(handle.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Scaffold(
          body: MessageSelectionTarget(
            handle: handle,
            child: Builder(
              builder: (context) => TextMessageStrategy().buildContent(
                context,
                ChatMessage(
                  messageType: MessageType.text,
                  content: 'plain message text',
                ),
                Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
    await dragText(tester, find.text('plain message text'));
    expect(handle.selectedText?.call(), isNotEmpty);
  });
}

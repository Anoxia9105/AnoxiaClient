import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/features/chat/models/message_item.dart';
import 'package:anoxia/features/chat/presentation/widgets/chat_message_list_delegate.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [390.0, 800.0, 1440.0]) {
    testWidgets('宽度 $width：插入消息时保留已有文字头像节点', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final old = ChatMessage(messageId: 'server-old', content: '旧');
      await _pumpList(tester, [MessageItem(old), TimeDividerItem(1)]);
      final avatar = tester.element(find.text('旧', skipOffstage: false));
      final paragraph = tester.renderObject(
        find.text('旧', skipOffstage: false),
      );

      await _pumpList(tester, [
        MessageItem(ChatMessage(clientMsgId: 'client-new', content: '新')),
        MessageItem(old),
        TimeDividerItem(1),
      ]);

      expect(tester.element(find.text('旧', skipOffstage: false)), same(avatar));
      expect(
        tester.renderObject(find.text('旧', skipOffstage: false)),
        same(paragraph),
      );
      expect(find.text('新', skipOffstage: false), findsOneWidget);
    });
  }

  testWidgets('服务端确认消息后保留文字头像节点', (tester) async {
    final sending = ChatMessage(clientMsgId: 'client-1', content: '我');
    await _pumpList(tester, [MessageItem(sending)]);
    final avatar = tester.element(find.text('我', skipOffstage: false));
    await _pumpList(tester, [
      MessageItem(sending.copyWith(messageId: 'server-1', timestamp: 123)),
    ]);
    expect(tester.element(find.text('我', skipOffstage: false)), same(avatar));
  });

  testWidgets('加载历史及删除前面的消息时保留现有头像', (tester) async {
    final newest = ChatMessage(clientMsgId: 'newest', content: '新');
    final old = ChatMessage(messageId: 'old', clientMsgId: '', content: '旧');
    await _pumpList(tester, [MessageItem(newest), MessageItem(old)]);
    final avatar = tester.element(find.text('旧', skipOffstage: false));
    await _pumpList(tester, [
      MessageItem(newest),
      MessageItem(old),
      TimeDividerItem(2),
      MessageItem(ChatMessage(messageId: 'history', content: '史')),
      TimeDividerItem(1),
    ]);
    expect(tester.element(find.text('旧', skipOffstage: false)), same(avatar));
    await _pumpList(tester, [MessageItem(old), TimeDividerItem(2)]);
    expect(tester.element(find.text('旧', skipOffstage: false)), same(avatar));
  });

  testWidgets('同值客户端 ID、服务端 ID 与时间戳不互相复用', (tester) async {
    await _pumpList(tester, [
      MessageItem(ChatMessage(clientMsgId: '1', content: '甲')),
      MessageItem(ChatMessage(messageId: '1', content: '乙')),
      TimeDividerItem(1),
    ]);
    expect(find.text('甲', skipOffstage: false), findsOneWidget);
    expect(find.text('乙', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpList(WidgetTester tester, List<ChatListItem> items) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FlutterListView(
          reverse: true,
          delegate: buildChatMessageListDelegate(items, (context, item) {
            return switch (item) {
              MessageItem(:final message) => SizedBox(
                height: 64,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AvatarWidget(name: message.content),
                ),
              ),
              TimeDividerItem() => const SizedBox(height: 20),
            };
          }),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

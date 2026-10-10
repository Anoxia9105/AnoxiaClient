import 'package:anoxia/features/chat/presentation/widgets/chatinput/mobile/chat_action_pager.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/mobile/chat_action_item.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> show(WidgetTester tester, int count, double width) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            child: SizedBox(
              width: width,
              height: 260,
              child: ChatActionPager(
                actions: List.generate(
                  count,
                  (i) => ChatActionItem(
                    icon: HugeIcons.strokeRoundedImage02,
                    label: 'action $i',
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('八个操作在窄屏同页显示且没有分页指示', (tester) async {
    await show(tester, 8, 320);
    expect(find.text('action 7'), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNothing);
    final first = tester.getTopLeft(find.text('action 0'));
    final fourth = tester.getTopLeft(find.text('action 3'));
    final fifth = tester.getTopLeft(find.text('action 4'));
    expect(first.dy, fourth.dy);
    expect(fifth.dy, greaterThan(first.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('第九个操作可以横滑访问并显示分页指示', (tester) async {
    await show(tester, 9, 390);
    expect(find.byType(AnimatedContainer), findsNWidgets(2));
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(find.text('action 8').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('操作减少后回到有效页，分页指示随之隐藏', (tester) async {
    await show(tester, 9, 390);
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();
    await show(tester, 8, 390);
    await tester.pumpAndSettle();
    expect(find.text('action 0').hitTestable(), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

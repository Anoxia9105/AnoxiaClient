import 'package:anoxia/features/chat/presentation/widgets/message_menu/message_reaction_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('鼠标移入显示紧凑表情条，移入表情条保持并可选择', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MessageReactionHover(
              onSelected: (value) => selected = value,
              timeLabel: '12:34',
              sideInset: 28,
              child: const SizedBox(width: 150, height: 60, child: Text('消息')),
            ),
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(10, 10));
    expect(find.byType(MessageReactionPicker), findsNothing);
    await mouse.moveTo(tester.getCenter(find.text('消息')));
    await tester.pump();
    expect(find.byType(MessageReactionPicker), findsOneWidget);
    final bubbleRect = tester.getRect(find.byType(MessageReactionHover));
    expect(
      tester.getTopLeft(find.byType(MessageReactionPicker)).dx,
      bubbleRect.left,
    );
    expect(find.text('12:34'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('12:34')).dx,
      greaterThanOrEqualTo(bubbleRect.right + 28),
    );

    expect(
      tester.getSize(find.byType(MessageReactionPicker)),
      const Size(218, 38),
    );
    await mouse.moveTo(tester.getCenter(find.text('👍')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(MessageReactionPicker), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == '👍',
      ),
    );
    await tester.pump();
    expect(selected, '👍');
    expect(find.byType(MessageReactionPicker), findsNothing);
    await mouse.moveTo(const Offset(10, 10));
    await mouse.moveTo(tester.getCenter(find.text('消息')));
    await tester.pump();
    await mouse.moveTo(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(MessageReactionPicker), findsNothing);
    await mouse.removePointer();
  });

  testWidgets('触屏菜单顶部表情条一行显示，点击直接回传回应', (tester) async {
    String? selected;
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => GestureDetector(
              onLongPress: () async {
                selected = await showMenu<String>(
                  context: context,
                  position: const RelativeRect.fromLTRB(20, 120, 20, 0),
                  constraints: const BoxConstraints(
                    minWidth: 288,
                    maxWidth: 296,
                  ),
                  items: [
                    PopupMenuItem<String>(
                      enabled: false,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: MessageReactionPicker(
                        touch: true,
                        onSelected: (value) => Navigator.of(context).pop(value),
                      ),
                    ),
                    const PopupMenuItem(value: 'copy', child: Text('复制')),
                  ],
                );
              },
              child: const SizedBox(width: 150, height: 60, child: Text('消息')),
            ),
          ),
        ),
      ),
    );
    await tester.longPress(find.text('消息'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MessageReactionPicker)).height, 48);
    await tester.tap(find.text('❤️'));
    await tester.pumpAndSettle();
    expect(selected, '❤️');
    expect(find.byType(MessageReactionPicker), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('不可回应消息悬停不显示表情条', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageReactionHover(
            enabled: false,
            onSelected: (_) {},
            child: const Text('消息'),
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(500, 500));
    await mouse.moveTo(tester.getCenter(find.text('消息')));
    await tester.pump();
    expect(find.byType(MessageReactionPicker), findsNothing);
    await mouse.removePointer();
  });
  testWidgets('滚动或移除消息时关闭悬停表情条', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: controller,
            children: [
              const SizedBox(height: 100),
              MessageReactionHover(
                onSelected: (_) {},
                child: const SizedBox(height: 60, child: Text('消息')),
              ),
              const SizedBox(height: 1600),
            ],
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(790, 590));
    await mouse.moveTo(tester.getCenter(find.text('消息')));
    await tester.pump();
    expect(find.byType(MessageReactionPicker), findsOneWidget);
    controller.jumpTo(50);
    await tester.pump();
    expect(find.byType(MessageReactionPicker), findsNothing);
    await mouse.moveTo(const Offset(790, 590));
    await mouse.moveTo(tester.getCenter(find.text('消息')));
    await tester.pump();
    expect(find.byType(MessageReactionPicker), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();
    expect(find.byType(MessageReactionPicker), findsNothing);
    expect(tester.takeException(), isNull);
    await mouse.removePointer();
  });
}

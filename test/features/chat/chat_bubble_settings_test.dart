import 'package:anoxia/common/constants/storage_keys.dart';
import 'package:anoxia/common/utils/sp_util.dart';
import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_bubble/bubble_shell.dart';
import 'package:anoxia/framework/provider/setting/chat_bubble_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('回应撑宽气泡并跨过下缘，后续消息留在回应下方', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(chatBubbleTailEnabledProvider.notifier).setEnabled(true);
    const footerKey = ValueKey('reaction-footer');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BubbleShell(
                  isCurrentUser: true,
                  backgroundColor: Colors.blue,
                  footer: SizedBox(key: footerKey, width: 160, height: 28),
                  child: Text('短消息'),
                ),
                Text('下一条'),
              ],
            ),
          ),
        ),
      ),
    );
    final bubble = tester.getRect(find.byType(BubbleWidget));
    final footer = tester.getRect(find.byKey(footerKey));
    expect(bubble.width, greaterThan(footer.width));
    expect(bubble.bottom, greaterThan(footer.top));
    expect(bubble.bottom, lessThan(footer.bottom));
    expect(
      tester.getTopLeft(find.text('下一条')).dy,
      greaterThanOrEqualTo(footer.bottom),
    );
  });
  testWidgets('气泡开关立即切换双方尖角并保存本机偏好', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SPUtil.instance.init();
    await SPUtil.instance.delete(StorageKeys.chatBubbleTailEnabled);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BubbleShell(
                  isCurrentUser: true,
                  backgroundColor: Colors.blue,
                  child: Text('自己'),
                ),
                BubbleShell(
                  isCurrentUser: false,
                  backgroundColor: Colors.grey,
                  child: Text('对方'),
                ),
                BubbleShell(
                  isCurrentUser: true,
                  placeOnLeft: true,
                  backgroundColor: Colors.blue,
                  child: SizedBox(height: 120, child: Text('全部靠左模式')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(BubbleWidget), findsNothing);
    container.read(chatBubbleTailEnabledProvider.notifier).setEnabled(true);
    await tester.pumpAndSettle();
    final bubbles = tester
        .widgetList<BubbleWidget>(find.byType(BubbleWidget))
        .toList();
    expect(bubbles.map((b) => b.arrowDirection), [
      AxisDirection.right,
      AxisDirection.left,
      AxisDirection.left,
    ]);
    for (final bubble in bubbles) {
      expect(bubble.arrowOffset, 18);
      final size = tester.getSize(find.byWidget(bubble));
      expect(size.height, greaterThanOrEqualTo(36));
      final shape = BubbleShapeBorder(
        arrowDirection: bubble.arrowDirection,
        arrowLength: bubble.arrowLength,
        arrowWidth: bubble.arrowWidth,
        arrowRadius: bubble.arrowRadius,
        arrowOffset: bubble.arrowOffset,
        borderRadius: bubble.borderRadius!,
      );
      final bounds = shape.getOuterPath(Offset.zero & size).getBounds();
      expect(bounds.top, greaterThanOrEqualTo(-0.01));
      expect(bounds.bottom, lessThanOrEqualTo(size.height + 0.01));
    }
    expect(SPUtil.instance.getBool(StorageKeys.chatBubbleTailEnabled), isTrue);
    final restored = ProviderContainer();
    expect(restored.read(chatBubbleTailEnabledProvider), isTrue);
    restored.dispose();
    container.read(chatBubbleTailEnabledProvider.notifier).setEnabled(false);
    await tester.pumpAndSettle();
    expect(find.byType(BubbleWidget), findsNothing);
    expect(find.text('自己'), findsOneWidget);
    expect(find.text('对方'), findsOneWidget);
    expect(SPUtil.instance.getBool(StorageKeys.chatBubbleTailEnabled), isFalse);
  });
}

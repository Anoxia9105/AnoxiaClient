import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_bubble/message_reaction_bar.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_emoji_bubble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/domain/repositories/message_repository.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/provider/core/message_repository_provider.dart';
import 'package:anoxia/framework/provider/chat/message/chat_reaction_service.dart';

class _ReactionRepository implements MessageRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('超过五种回应时折叠，并在底部向上展开', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final emojis = [...reactionEmojiPalette, '🎉'];
    final reactions = container.read(roomChatReactionsProvider.notifier);
    for (var i = 0; i < emojis.length; i++) {
      reactions.applyEvent(
        roomId: 'r',
        messageId: 'm',
        emoji: emojis[i],
        isRemove: false,
        senderUserId: i + 1,
        currentUserId: null,
        senderName: '回应者${i + 1}',
      );
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomRight,
              child: MessageReactionBar(
                message: ChatMessage(roomId: 'r', messageId: 'm'),
              ),
            ),
          ),
        ),
      ),
    );
    final more = find.text('+2');
    expect(more, findsOneWidget);
    expect(find.text('回应者6'), findsNothing);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(10, 10));
    await mouse.moveTo(tester.getCenter(more));
    await tester.pumpAndSettle();
    final hiddenUser = find.text('回应者6');
    expect(hiddenUser, findsOneWidget);
    expect(
      tester.getCenter(hiddenUser).dy,
      lessThan(tester.getCenter(more).dy),
    );
    await mouse.moveTo(tester.getCenter(hiddenUser));
    await tester.pump(const Duration(milliseconds: 300));
    expect(hiddenUser, findsOneWidget);
    await mouse.moveTo(const Offset(10, 10));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(hiddenUser, findsNothing);
    await mouse.removePointer();
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(hiddenUser, findsOneWidget);
  });
  test('更多表情浮层在消息上下方翻转时尖角仍对准消息', () {
    for (final screen in [const Size(320, 700), const Size(1280, 800)]) {
      for (final left in [16.0, screen.width - 96]) {
        for (final top in [40.0, screen.height - 80]) {
          final target = Rect.fromLTWH(left, top, 64, 36);
          final width = (screen.width - 32).clamp(0.0, 344.0);
          final placement = resolveAnchoredBubblePlacement(
            targetRect: target,
            screenSize: screen,
            bubbleWidth: width,
            estimatedHeight: 330,
            preferRightArrow: target.center.dx >= screen.width / 2,
          );
          expect(
            placement.left + placement.arrowOffset,
            closeTo(target.center.dx, 0.01),
          );
          expect(
            placement.arrowDirection,
            top < 100 ? AxisDirection.up : AxisDirection.down,
          );
          expect(
            placement.anchorY,
            placement.showBelow ? target.bottom : target.top,
          );
          expect(placement.left, greaterThanOrEqualTo(12));
          expect(placement.left + width, lessThanOrEqualTo(screen.width - 12));
        }
      }
    }
  });
  test('共享 Emoji 气泡支持输入框连续选择与回应单次选择', () {
    final input = ChatEmojiBubble(
      onEmojiSelected: (_) {},
      onStickerSelected: (_) {},
    );
    final reaction = ChatEmojiBubble(
      onEmojiSelected: (_) {},
      onStickerSelected: (_) {},
      emojiOnly: true,
      closeOnSelect: true,
    );
    expect(input.closeOnSelect, isFalse);
    expect(input.emojiOnly, isFalse);
    expect(reaction.closeOnSelect, isTrue);
    expect(reaction.emojiOnly, isTrue);
  });
  test('回应事件增删本地用户缓存，乐观切换及回滚同步昵称', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(roomChatReactionsProvider.notifier);
    notifier.applyEvent(
      roomId: 'r',
      messageId: 'm',
      emoji: '👍',
      isRemove: false,
      senderUserId: 2,
      currentUserId: 1,
      senderName: '小豆',
    );
    notifier.toggleLocal(
      'r',
      'm',
      '👍',
      currentUserId: 1,
      currentUserName: '我',
    );
    expect(
      container
          .read(roomChatReactionsProvider)['r']!
          .byMessage['m']!['👍']!
          .users,
      {2: '小豆', 1: '我'},
    );
    notifier.toggleLocal(
      'r',
      'm',
      '👍',
      currentUserId: 1,
      currentUserName: '我',
    );
    expect(
      container
          .read(roomChatReactionsProvider)['r']!
          .byMessage['m']!['👍']!
          .users,
      {2: '小豆'},
    );
    notifier.applyEvent(
      roomId: 'r',
      messageId: 'm',
      emoji: '👍',
      isRemove: true,
      senderUserId: 2,
      currentUserId: 1,
    );
    expect(container.read(roomChatReactionsProvider)['r']!.byMessage, isEmpty);
  });
  test('快捷回应固定六个常用表情且不重复', () {
    expect(reactionEmojiPalette, ['👍', '❤️', '😂', '😮', '😢', '🙏']);
    expect(reactionEmojiPalette.toSet().length, 6);
  });
  testWidgets('悬停只显示缓存昵称，不调用仓库接口', (tester) async {
    final container = ProviderContainer(
      overrides: [
        messageRepositoryProvider.overrideWithValue(_ReactionRepository()),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(roomChatReactionsProvider.notifier)
        .replaceWindow(
          'room',
          ['message'],
          [(messageId: 'message', emoji: '👍', count: 2, mine: false)],
          usersByMessage: {
            'message': {
              '👍': {1: '小豆', 2: '测试01'},
            },
          },
        );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: MessageReactionBar(
              message: ChatMessage(roomId: 'room', messageId: 'message'),
            ),
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(700, 500));
    await mouse.moveTo(tester.getCenter(find.text('👍')));
    await tester.pumpAndSettle();
    expect(find.text('小豆、测试01'), findsOneWidget);
    await mouse.removePointer();
  });
}

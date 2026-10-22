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

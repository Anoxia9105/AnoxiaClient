// 表情回应内存态状态机测试
//
// 覆盖点：他人/本人事件计数、本地乐观切换与 ACK 失败回滚（toggle 自逆）、
// 本人回声去重、REST 补拉窗口覆盖（含离线被撤空组）、容量淘汰与会话清理。
import 'package:anoxia/framework/provider/chat/message/chat_reaction_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late RoomChatReactions notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(roomChatReactionsProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  RoomReactionBoard boardOf(String roomId) =>
      container.read(roomChatReactionsProvider)[roomId] ??
      const RoomReactionBoard({});

  RoomReactionAggregate? aggOf(
    String roomId,
    String messageId,
    String emoji,
  ) {
    final groups = boardOf(roomId).byMessage[messageId];
    return groups?[emoji];
  }

  test('其他用户添加事件累加计数且不影响 mine', () {
    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm1',
      emoji: '👍',
      isRemove: false,
      senderUserId: 9,
      currentUserId: 7,
    );

    final agg = aggOf('room-a', 'm1', '👍')!;
    expect(agg.count, 1);
    expect(agg.mine, isFalse);
  });

  test('本人事件把 mine 置真（其他设备同步进来的场景）', () {
    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm1',
      emoji: '❤️',
      isRemove: false,
      senderUserId: 7,
      currentUserId: 7,
    );

    final agg = aggOf('room-a', 'm1', '❤️')!;
    expect(agg.count, 1);
    expect(agg.mine, isTrue);
  });

  test('本人回声去重：已处于目标态时不重复计数', () {
    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm1',
      emoji: '👍',
      isRemove: false,
      senderUserId: 7,
      currentUserId: 7,
    );
    // 模拟本地点击后的广播回声
    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm1',
      emoji: '👍',
      isRemove: false,
      senderUserId: 7,
      currentUserId: 7,
    );

    final agg = aggOf('room-a', 'm1', '👍')!;
    expect(agg.count, 1);
    expect(agg.mine, isTrue);
  });

  test('他人撤销事件减计数，归零后整组移除', () {
    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm1',
      emoji: '👍',
      isRemove: false,
      senderUserId: 9,
      currentUserId: 7,
    );
    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm1',
      emoji: '👍',
      isRemove: true,
      senderUserId: 9,
      currentUserId: 7,
    );

    expect(aggOf('room-a', 'm1', '👍'), isNull);
    expect(boardOf('room-a').byMessage['m1'], isNull);
  });

  test('本人撤销：本地先落 mine=false，广播回声不再二次减计数', () {
    // 他人先来了一个，我的另一设备随后也点了一个
    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm1',
      emoji: '👍',
      isRemove: false,
      senderUserId: 9,
      currentUserId: 7,
    );
    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm1',
      emoji: '👍',
      isRemove: false,
      senderUserId: 7,
      currentUserId: 7,
    );
    expect(aggOf('room-a', 'm1', '👍')!.count, 2);

    // 本地点击撤销（乐观）：mine 变 false，计数先减
    expect(notifier.toggleLocal('room-a', 'm1', '👍'), isFalse);
    expect(aggOf('room-a', 'm1', '👍')!.count, 1);
    expect(aggOf('room-a', 'm1', '👍')!.mine, isFalse);

    // 广播回声（sender=me, remove）：本地已处于目标态 → 跳过
    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm1',
      emoji: '👍',
      isRemove: true,
      senderUserId: 7,
      currentUserId: 7,
    );
    final agg = aggOf('room-a', 'm1', '👍')!;
    expect(agg.count, 1);
    expect(agg.mine, isFalse);
  });

  test('空状态首击等价于添加（chip 与菜单首点共用入口）', () {
    expect(notifier.toggleLocal('room-a', 'm9', '👍'), isTrue);
    final agg = aggOf('room-a', 'm9', '👍')!;
    expect(agg.count, 1);
    expect(agg.mine, isTrue);
  });

  test('toggleLocal 自逆：添加后再切换即还原，可作 ACK 失败回滚', () {
    expect(notifier.toggleLocal('room-a', 'm1', '👍'), isTrue);
    expect(aggOf('room-a', 'm1', '👍')!.mine, isTrue);
    expect(aggOf('room-a', 'm1', '👍')!.count, 1);

    // ACK 失败回滚 = 再 toggle 一次
    expect(notifier.toggleLocal('room-a', 'm1', '👍'), isFalse);
    expect(boardOf('room-a').byMessage['m1'], isNull);
  });

  test('他人期间新增计数不破坏 optimistic 还原精度', () {
    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm1',
      emoji: '👍',
      isRemove: false,
      senderUserId: 9,
      currentUserId: 7,
    );
    expect(notifier.toggleLocal('room-a', 'm1', '👍'), isTrue);
    expect(aggOf('room-a', 'm1', '👍')!.count, 2);

    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm1',
      emoji: '👍',
      isRemove: false,
      senderUserId: 8,
      currentUserId: 7,
    );
    expect(aggOf('room-a', 'm1', '👍')!.count, 3);

    // 本人回声：mine 已 true → 不计数
    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm1',
      emoji: '👍',
      isRemove: false,
      senderUserId: 7,
      currentUserId: 7,
    );
    expect(aggOf('room-a', 'm1', '👍')!.count, 3);
  });

  test('replaceWindow 覆盖窗口内空组并跳过无变化数据', () {
    notifier.toggleLocal('room-a', 'm1', '👍'); // 离线期间他人撤销 → 变陈旧
    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm2',
      emoji: '🔥',
      isRemove: false,
      senderUserId: 9,
      currentUserId: 7,
    );

    notifier.replaceWindow('room-a', ['m1', 'm2'], const [
      (messageId: 'm2', emoji: '🔥', count: 4, mine: false),
    ]);

    // m1 被 REST 判定为空 → 整组清除
    expect(boardOf('room-a').byMessage['m1'], isNull);
    // m2 计数被服务端权威值覆盖
    final agg = aggOf('room-a', 'm2', '🔥')!;
    expect(agg.count, 4);
    expect(agg.mine, isFalse);
  });

  test('replaceWindow 的行同步返回同值时保持状态不变', () {
    notifier.replaceWindow('room-a', ['m2'], const [
      (messageId: 'm2', emoji: '🔥', count: 4, mine: false),
    ]);
    final before = boardOf('room-a').byMessage['m2'];

    notifier.replaceWindow('room-a', ['m2'], const [
      (messageId: 'm2', emoji: '🔥', count: 4, mine: false),
    ]);

    final after = boardOf('room-a').byMessage['m2'];
    expect(identical(before, after), isTrue);
  });

  test('窗口外消息不受补拉影响', () {
    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm-out',
      emoji: '🙏',
      isRemove: false,
      senderUserId: 9,
      currentUserId: 7,
    );
    notifier.replaceWindow('room-a', ['m1'], const []);

    expect(aggOf('room-a', 'm-out', '🙏'), isNotNull);
  });

  test('clear 只清理指定房间', () {
    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm1',
      emoji: '👍',
      isRemove: false,
      senderUserId: 9,
      currentUserId: 7,
    );
    notifier.applyEvent(
      roomId: 'room-b',
      messageId: 'm1',
      emoji: '👍',
      isRemove: false,
      senderUserId: 9,
      currentUserId: 7,
    );

    notifier.clear('room-a');

    expect(container.read(roomChatReactionsProvider).containsKey('room-a'),
        isFalse);
    expect(
      container.read(roomChatReactionsProvider).containsKey('room-b'),
      isTrue,
    );
  });

  test('单房间上限淘汰最旧消息', () {
    for (var i = 0; i < 501; i++) {
      notifier.applyEvent(
        roomId: 'room-a',
        messageId: 'm-$i',
        emoji: '👍',
        isRemove: false,
        senderUserId: 9,
        currentUserId: 7,
      );
    }

    final byMessage = boardOf('room-a').byMessage;
    expect(byMessage.length, 500);
    expect(byMessage['m-0'], isNull);
    expect(byMessage['m-500'], isNotNull);
  });

  test('无效入参（空 roomId/emoji）静默忽略', () {
    notifier.applyEvent(
      roomId: '',
      messageId: 'm1',
      emoji: '👍',
      isRemove: false,
      senderUserId: 9,
      currentUserId: 7,
    );
    notifier.applyEvent(
      roomId: 'room-a',
      messageId: 'm1',
      emoji: '',
      isRemove: false,
      senderUserId: 9,
      currentUserId: 7,
    );

    expect(container.read(roomChatReactionsProvider), isEmpty);
  });
}

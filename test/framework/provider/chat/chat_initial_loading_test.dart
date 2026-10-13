import 'dart:async';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:anoxia/framework/provider/auth/token_provider.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_ui_item_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('首次进入：本地先返回空列表，远端同步结束前仍显示骨架屏', () async {
    final sync = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        roomEntryTaskProvider('room').overrideWith((ref) => sync.future),
        roomMessagesProvider('room').overrideWith((ref) => Stream.value([])),
      ],
    );
    addTearDown(container.dispose);
    final listener = container.listen(
      chatInitialLoadingProvider('room'),
      (_, _) {},
    );
    addTearDown(listener.close);
    expect(container.read(chatInitialLoadingProvider('room')), isTrue);
    await container.read(roomMessagesProvider('room').future);
    expect(container.read(chatInitialLoadingProvider('room')), isTrue);
    sync.complete();
    await container.read(roomEntryTaskProvider('room').future);
    expect(container.read(chatInitialLoadingProvider('room')), isFalse);
  });

  test('初始化结束后，本地消息流尚未返回时继续显示骨架屏', () async {
    final messages = StreamController<List<ChatMessage>>();
    final container = ProviderContainer(
      overrides: [
        roomEntryTaskProvider('room').overrideWith((ref) async {}),
        roomMessagesProvider('room').overrideWith((ref) => messages.stream),
      ],
    );
    addTearDown(messages.close);
    addTearDown(container.dispose);
    final listener = container.listen(
      chatInitialLoadingProvider('room'),
      (_, _) {},
    );
    addTearDown(listener.close);
    await container.read(roomEntryTaskProvider('room').future);
    expect(container.read(chatInitialLoadingProvider('room')), isTrue);
    messages.add([]);
    await container.read(roomMessagesProvider('room').future);
    expect(container.read(chatInitialLoadingProvider('room')), isFalse);
  });

  for (final empty in [true, false]) {
    test('切回已加载${empty ? '空' : ''}房间，重新同步期间不闪骨架屏', () async {
      final sync = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          roomEntryTaskProvider('room').overrideWith((ref) => sync.future),
          roomMessagesProvider('room').overrideWith(
            (ref) => Stream.value(
              empty ? [] : [ChatMessage(messageId: 'cached', roomId: 'room')],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(roomInitialLoadsProvider.notifier).markLoaded('room');
      final messages = container.listen(
        roomMessagesProvider('room'),
        (_, _) {},
      );
      addTearDown(messages.close);
      await container.read(roomMessagesProvider('room').future);
      final first = container.listen(
        chatInitialLoadingProvider('room'),
        (_, _) {},
      );
      expect(container.read(chatInitialLoadingProvider('room')), isFalse);
      first.close();
      await container.pump();
      final second = container.listen(
        chatInitialLoadingProvider('room'),
        (_, _) {},
      );
      addTearDown(second.close);
      expect(container.read(roomEntryTaskProvider('room')).isLoading, isTrue);
      expect(container.read(chatInitialLoadingProvider('room')), isFalse);
      sync.complete();
      await container.read(roomEntryTaskProvider('room').future);
    });
  }

  test('首次加载已有本地消息时直接显示消息', () async {
    final sync = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        roomEntryTaskProvider('room').overrideWith((ref) => sync.future),
        roomMessagesProvider('room').overrideWith(
          (ref) =>
              Stream.value([ChatMessage(messageId: 'cached', roomId: 'room')]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final listener = container.listen(
      chatInitialLoadingProvider('room'),
      (_, _) {},
    );
    addTearDown(listener.close);
    await container.read(roomMessagesProvider('room').future);
    expect(container.read(chatInitialLoadingProvider('room')), isFalse);
    sync.complete();
    await container.read(roomEntryTaskProvider('room').future);
  });

  test('初始化失败后退出骨架屏，交给页面显示错误', () async {
    final container = ProviderContainer(
      overrides: [
        roomEntryTaskProvider('room').overrideWith((ref) async {
          throw StateError('offline');
        }),
        roomMessagesProvider('room').overrideWith((ref) => Stream.value([])),
      ],
    );
    addTearDown(container.dispose);
    final listener = container.listen(
      chatInitialLoadingProvider('room'),
      (_, _) {},
    );
    addTearDown(listener.close);
    await expectLater(
      container.read(roomEntryTaskProvider('room').future),
      throwsStateError,
    );
    expect(container.read(chatInitialLoadingProvider('room')), isFalse);
    expect(container.read(roomInitialLoadsProvider), isEmpty);
  });

  test('首次同步完成记录房间，重新进入仍同步，换账号清除记录', () async {
    final sync = Completer<void>();
    final chat = _Messages(sync.future);
    final container = ProviderContainer(
      overrides: [
        currentRoomProvider(
          'room',
        ).overrideWith((ref) => ChatRoomVO(roomId: 'room')),
        chatMessagesProvider.overrideWith(() => chat),
        roomMemberServiceProvider.overrideWith(_Members.new),
        roomListServiceProvider.overrideWith(_Rooms.new),
      ],
    );
    addTearDown(container.dispose);
    container.read(tokenCacheProvider.notifier).setToken('first');
    final first = container.listen(roomEntryTaskProvider('room'), (_, _) {});
    expect(container.read(roomInitialLoadsProvider), isEmpty);
    sync.complete();
    await container.read(roomEntryTaskProvider('room').future);
    expect(container.read(roomInitialLoadsProvider), {'room'});
    first.close();
    await container.pump();
    final second = container.listen(roomEntryTaskProvider('room'), (_, _) {});
    addTearDown(second.close);
    await container.read(roomEntryTaskProvider('room').future);
    expect(chat.syncs, 2);
    container.read(tokenCacheProvider.notifier).clearToken();
    expect(container.read(roomInitialLoadsProvider), isEmpty);
    container.read(tokenCacheProvider.notifier).setToken('second');
    expect(container.read(roomInitialLoadsProvider), isEmpty);
  });
}

class _Messages extends ChatMessages {
  _Messages(this.sync);
  final Future<void> sync;
  int syncs = 0;
  @override
  void build() {}
  @override
  Future<void> syncRoomMessages(String roomId, int? serverLastSeq) {
    syncs++;
    return sync;
  }
}

class _Members extends RoomMemberService {
  @override
  Map<String, Map<int, ChatRoomMemberVO>> build() => {};
  @override
  Future<void> syncMembers(
    String roomId, {
    bool force = false,
    Duration? timeout,
  }) async {}
}

class _Rooms extends RoomListService {
  @override
  Future<List<ChatRoomVO>> build() async => [];
  @override
  void markAsRead(String roomId) {}
}

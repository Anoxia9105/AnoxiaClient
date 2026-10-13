import 'dart:async';

import 'package:anoxia/domain/repositories/chat_repository.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/protocol/message/room_message.dart';
import 'package:anoxia/framework/protocol/packet_frame.dart';
import 'package:anoxia/framework/protocol/i_packet.dart';
import 'package:anoxia/framework/protocol/packet_type.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/do_not_disturb_rooms_provider.dart';
import 'package:anoxia/framework/provider/core/app_foreground_provider.dart';
import 'package:anoxia/framework/provider/core/chat_repository_provider.dart';
import 'package:anoxia/framework/provider/core/message_notification_sender_provider.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _Foreground extends AppForeground {
  @override
  bool build() => true;
  void setVisible(bool visible) => state = visible;
}

class _Auth extends AuthController {
  @override
  Future<UserInfo?> build() async => null;
  void setLoggedIn() => state = AsyncData(UserInfo.fromJson({'userId': 1}));
}

class _Ws extends WsController {
  final frames = StreamController<PacketFrame<IPacket>>.broadcast(sync: true);
  @override
  WsState build() {
    ref.onDispose(() => unawaited(frames.close()));
    return WsState(status: WsStatus.connected);
  }

  @override
  Stream<PacketFrame<IPacket>> get messageStream => frames.stream;
  @override
  Future<void> flushReadCursors() async {}
}

class _Repository implements ChatRepository {
  _Repository(this.local);
  final LocalDataSource local;
  @override
  Stream<List<ChatRoomVO>> watchConversations() => local.watchConversations();
  @override
  Future<List<ChatRoomVO>> getConversations({bool sync = true}) =>
      local.getConversations();
  @override
  Future<void> syncConversations({bool throwOnError = false}) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Muted extends DoNotDisturbRooms {
  @override
  Set<String> build() => {};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late LocalDataSource local;
  late ProviderContainer container;
  late _Ws ws;
  late _Foreground foreground;
  late ChatMessages messages;
  late List<String?> notifications;

  Future<void> settle() async {
    for (var i = 0; i < 8; i++) {
      // 测试环境没有帧循环，Riverpod 3 的依赖刷新是惰性的；
      // 显式读取推进传播链，模拟真实 UI 每帧读取阅读状态。
      container.read(activelyViewedRoomIdProvider);
      await local.getConversations();
      await Future<void>.delayed(Duration.zero);
      await container.pump();
    }
  }

  Future<int> unread() async =>
      (await local.getConversations()).single.unreadCount ?? 0;
  int roomLastSeq() {
    final rooms = container.read(roomListServiceProvider).value;
    if (rooms == null || rooms.isEmpty) return 0;
    return rooms.first.lastMessage?.seq ?? 0;
  }

  /// 轮询直到异步副作用落定，避免依赖固定轮数的 settle。
  Future<void> waitFor(String label, Future<bool> Function() ready) async {
    for (var i = 0; i < 400; i++) {
      container.read(activelyViewedRoomIdProvider);
      final ok = await ready();
      if (ok) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await container.pump();
    }
    final rooms = container
        .read(roomListServiceProvider)
        .value
        ?.map((r) => '${r.roomId}:u=${r.unreadCount},seq=${r.lastMessage?.seq}')
        .join(';');
    fail(
      '等待异步条件超时: $label; rooms=$rooms; pending=${await local.pendingReadCursors()}; unread=${await unread()}',
    );
  }

  Future<void> receive(int seq, {int sender = 2}) async {
    ws.frames.add(
      PacketFrame(
        topic: PacketType.message,
        data: RoomMessage(
          messageId: 'm$seq',
          clientMsgId: 'c$seq',
          roomId: 'room',
          senderId: sender,
          messageType: MessageType.text,
          payload: const MessagePayload(content: '你好'),
          seq: seq,
          serverTimestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      ),
    );
    await messages.markAcked(clientMsgId: 'missing');
    await settle();
  }

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    database = AppDatabase(NativeDatabase.memory());
    local = LocalDataSource(database);
    ws = _Ws();
    foreground = _Foreground();
    notifications = [];
    container = ProviderContainer(
      overrides: [
        localDataSourceProvider.overrideWithValue(local),
        chatRepositoryProvider.overrideWithValue(_Repository(local)),
        authControllerProvider.overrideWith(_Auth.new),
        appForegroundProvider.overrideWith(() => foreground),
        wsControllerProvider.overrideWith(() => ws),
        doNotDisturbRoomsProvider.overrideWith(_Muted.new),
        messageNotificationSenderProvider.overrideWith(
          (ref) =>
              ({
                required int id,
                required String title,
                required String body,
                String? payload,
                String? avatarUrl,
              }) async {
                notifications.add(payload);
              },
        ),
      ],
    );
    await container.read(roomListServiceProvider.future);
    // auth 是 autoDispose，保持常驻监听避免测试期间被回收后重建为 null。
    container.listen(authControllerProvider, (_, _) {});
    await container.read(authControllerProvider.future);
    (container.read(authControllerProvider.notifier) as _Auth).setLoggedIn();
    await local.upsertConversation(
      ChatRoomVO(roomId: 'room', roomName: '测试', unreadCount: 0),
    );
    await settle();
    container.read(activeRoomIdProvider.notifier).setActive('room');
    messages = container.read(chatMessagesProvider.notifier);
    // setActive 触发的已读处理走微任务，先让它落定（此时无未读、无副作用），
    // 否则会拖到测试体内、在收到新消息之后才执行。
    await settle();
  });
  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    container.dispose();
    await database.close();
  });

  test('最小化仍选中房间：新消息保持未读、无已读游标且触发通知，恢复后才已读', () async {
    foreground.setVisible(false);
    await receive(1);
    expect(container.read(activeRoomIdProvider), 'room');
    await waitFor(
      '后台消息写入未读并通知',
      () async => (await unread()) == 1 && notifications.length == 1,
    );
    // 静默期：确认后台没有触发任何已读上报。
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await settle();
    expect(await unread(), 1);
    expect(await local.pendingReadCursors(), isEmpty);
    expect(notifications, ['room']);
    await container
        .read(roomListServiceProvider.notifier)
        .refresh(silent: true);
    await settle();
    expect(await unread(), 1);
    foreground.setVisible(true);
    await waitFor(
      '恢复前台后上报 seq=1',
      () async => (await local.pendingReadCursors())['room'] == 1,
    );
    await settle();
    expect(await unread(), 0);
    expect(await local.pendingReadCursors(), {'room': 1});
  });

  test('前台已见消息的防抖不会在最小化后清除新消息未读', () async {
    await receive(1);
    expect(await unread(), 0);
    expect(notifications, isEmpty);
    foreground.setVisible(false);
    // 前台已见消息的防抖在失焦时立即冲刷，产生 seq=1 的待上报游标。
    await waitFor(
      '恢复前台后上报 seq=1',
      () async => (await local.pendingReadCursors())['room'] == 1,
    );
    await receive(2);
    await waitFor('后台收到 seq=2 未读 +1', () async => (await unread()) == 1);
    expect(await local.pendingReadCursors(), {'room': 1});
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    await settle();
    expect(await unread(), 1);
    expect(await local.pendingReadCursors(), {'room': 1});
    foreground.setVisible(true);
    await waitFor(
      '恢复前台后上报 seq=2',
      () async => (await local.pendingReadCursors())['room'] == 2,
    );
    await settle();
    expect(await unread(), 0);
    expect(await local.pendingReadCursors(), {'room': 2});
  });

  test('后台自己发送的消息不增加未读、不通知', () async {
    foreground.setVisible(false);
    await receive(1, sender: 1);
    await waitFor('自己消息落库', () async => roomLastSeq() == 1);
    // 静默期：确认后台没有触发通知或已读上报。
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await settle();
    expect(await unread(), 0);
    expect(notifications, isEmpty);
  });
}

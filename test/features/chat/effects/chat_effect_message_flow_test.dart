import 'dart:async';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/protocol/i_packet.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/protocol/message/room_message.dart';
import 'package:anoxia/framework/protocol/packet_frame.dart';
import 'package:anoxia/framework/protocol/packet_type.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/effect/chat_effect_dispatcher.dart';
import 'package:anoxia/framework/provider/chat/effect/chat_effect_provider.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Ws extends WsController {
  final frames = StreamController<PacketFrame<IPacket>>.broadcast(sync: true);

  @override
  WsState build() {
    ref.onDispose(() => unawaited(frames.close()));
    return WsState(status: WsStatus.connected);
  }

  @override
  Stream<PacketFrame<IPacket>> get messageStream => frames.stream;
}

class _Auth extends AuthController {
  @override
  Future<UserInfo?> build() async => UserInfo.fromJson({'userId': 1});
}

class _Rooms extends RoomListService {
  @override
  FutureOr<List<ChatRoomVO>> build() => [];

  @override
  void updateRoomPosition(ChatMessage newMessage, String? roomId) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late LocalDataSource local;
  late ProviderContainer container;
  late ChatMessages messages;
  late _Ws ws;
  late List<ChatEffectEvent> effects;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    local = LocalDataSource(database);
    ws = _Ws();
    container = ProviderContainer(
      overrides: [
        localDataSourceProvider.overrideWithValue(local),
        wsControllerProvider.overrideWith(() => ws),
        authControllerProvider.overrideWith(_Auth.new),
        roomListServiceProvider.overrideWith(_Rooms.new),
      ],
    );
    await container.read(authControllerProvider.future);
    effects = [];
    container.read(chatEffectDispatcherProvider).events.listen(effects.add);
    messages = container.read(chatMessagesProvider.notifier);
  });
  tearDown(() async {
    container.dispose();
    await database.close();
  });

  RoomMessage incoming({
    int senderId = 1,
    String id = 'server1',
    int? timestamp,
  }) => RoomMessage(
    messageId: id,
    clientMsgId: 'client1',
    roomId: 'room',
    senderId: senderId,
    messageType: MessageType.text,
    payload: const MessagePayload(content: '生日快乐'),
    seq: 1,
    serverTimestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
  );

  Future<void> receive(RoomMessage message) async {
    ws.frames.add(PacketFrame(topic: PacketType.message, data: message));
    // 用现有串行写队列的空 ACK 作屏障，不依赖 sleep 等待落库。
    await messages.markAcked(clientMsgId: 'missing');
    await Future<void>.delayed(Duration.zero);
  }

  for (final echoFirst in [false, true]) {
    test('真实消息落库：${echoFirst ? '回显先于 ACK' : 'ACK 先于回显'}只触发一次', () async {
      await local.upsertMessage(
        ChatMessage(
          messageId: 'client1',
          clientMsgId: 'client1',
          roomId: 'room',
          senderId: 1,
          messageType: MessageType.text,
          content: '生日快乐',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          deliveryStatus: DeliveryStatus.sending,
        ),
      );
      expect(effects, isEmpty);
      if (echoFirst) await receive(incoming());
      await messages.markAcked(
        clientMsgId: 'client1',
        messageId: 'server1',
        seq: 1,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      if (!echoFirst) await receive(incoming());
      await receive(incoming());
      expect(effects, hasLength(1));
      expect(
        (await local.getMessageByClientMsgId('client1'))?.deliveryStatus,
        DeliveryStatus.sent,
      );
    });
  }

  test('对方实时消息播放一次，重复推送不重播', () async {
    await receive(incoming(senderId: 2));
    await receive(incoming(senderId: 2));
    expect(effects, hasLength(1));
    expect((await local.getMessageById('server1'))?.content, '生日快乐');
  });

  test('离线旧祝福重试收到新的回显时间，也不补播', () async {
    await local.upsertMessage(
      ChatMessage(
        messageId: 'client1',
        clientMsgId: 'client1',
        roomId: 'room',
        senderId: 1,
        messageType: MessageType.text,
        content: '生日快乐',
        timestamp: DateTime.now()
            .subtract(const Duration(minutes: 1))
            .millisecondsSinceEpoch,
        deliveryStatus: DeliveryStatus.sending,
      ),
    );
    await receive(incoming());
    await messages.markAcked(
      clientMsgId: 'client1',
      messageId: 'server1',
      seq: 1,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    expect(effects, isEmpty);
    expect(
      (await local.getMessageById('server1'))?.deliveryStatus,
      DeliveryStatus.sent,
    );
  });

  test('历史落库和过期实时消息仍正常存储但不触发特效', () async {
    await local.upsertMessage(
      ChatMessage(
        messageId: 'history',
        roomId: 'room',
        senderId: 2,
        messageType: MessageType.text,
        content: '生日快乐',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await receive(
      incoming(
        senderId: 2,
        timestamp: DateTime.now()
            .subtract(const Duration(minutes: 1))
            .millisecondsSinceEpoch,
      ),
    );
    expect(effects, isEmpty);
    expect(await local.getMessageById('history'), isNotNull);
    expect(await local.getMessageById('server1'), isNotNull);
  });
}

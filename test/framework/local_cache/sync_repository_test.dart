import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/local_cache/remote_data_source.dart';
import 'package:anoxia/framework/local_cache/sync_repository.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakeConnectivityPlatform extends ConnectivityPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return [ConnectivityResult.wifi];
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

class _FakeRemoteDataSource extends RemoteDataSource {
  _FakeRemoteDataSource();

  List<ChatRoomVO>? rooms;

  final Map<String, List<ChatMessage>> history = {};

  int fetchMessagesCalls = 0;

  @override
  Future<List<ChatRoomVO>?> fetchConversations({DateTime? since}) async {
    return rooms;
  }

  @override
  Future<List<ChatMessage>> fetchMessages(
    String convId, {
    DateTime? since,
    int? lastSeq,
    int? beforeSeq,
    int pageSize = 100,
  }) async {
    fetchMessagesCalls++;
    final all = history[convId] ?? const <ChatMessage>[];
    return all
        .where((message) => (message.seq ?? 0) > (lastSeq ?? 0))
        .take(pageSize)
        .toList();
  }
}

ChatMessage _message({
  required String id,
  required String roomId,
  required int seq,
  int senderId = 42,
}) {
  return ChatMessage(
    messageId: id,
    clientMsgId: id,
    roomId: roomId,
    senderId: senderId,
    messageType: MessageType.text,
    content: 'content-$seq',
    seq: seq,
    timestamp: seq,
  );
}

void main() {
  late AppDatabase database;
  late LocalDataSource local;
  late _FakeRemoteDataSource remote;
  late SyncRepository syncRepository;

  setUp(() {
    ConnectivityPlatform.instance = _FakeConnectivityPlatform();
    database = AppDatabase(NativeDatabase.memory());
    local = LocalDataSource(database);
    remote = _FakeRemoteDataSource();
    syncRepository = SyncRepository(local: local, remote: remote);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'backlog sync loops until caught up and watermark reaches max seq',
    () async {
      remote.history['room-1'] = List.generate(
        250,
        (index) => _message(
          id: 'message-${index + 1}',
          roomId: 'room-1',
          seq: index + 1,
        ),
      );

      await syncRepository.syncMessages('room-1');

      expect(remote.fetchMessagesCalls, 3);
      expect(await local.messageSyncWatermark('room-1'), 250);
      final messages = await local.getMessagesForConversation(
        'room-1',
        limit: 1000,
      );
      expect(messages, hasLength(250));
      expect(
        messages.map((message) => message.seq).toSet(),
        List.generate(250, (index) => index + 1).toSet(),
      );
    },
  );

  test('watermark jumps past permanent holes inside the response', () async {
    remote.history['room-1'] = [
      for (final seq in [1, 2, 3, 5, 6, 7])
        _message(id: 'message-$seq', roomId: 'room-1', seq: seq),
    ];
    await local.updateSyncState(
      scope: 'messages',
      scopeId: 'room-1',
      lastSeq: 3,
    );

    await syncRepository.syncMessages('room-1');

    expect(remote.fetchMessagesCalls, 1);
    expect(await local.messageSyncWatermark('room-1'), 7);
    final messages = await local.getMessagesForConversation(
      'room-1',
      limit: 1000,
    );
    expect(messages.map((message) => message.seq).toSet(), {5, 6, 7});
  });

  test(
    'empty remote response breaks the loop without advancing watermark',
    () async {
      await local.updateSyncState(
        scope: 'messages',
        scopeId: 'room-1',
        lastSeq: 5,
      );

      await syncRepository.syncMessages('room-1');

      expect(remote.fetchMessagesCalls, 1);
      expect(await local.messageSyncWatermark('room-1'), 5);
    },
  );

  test(
    'conversation sync deletes stale local rooms with messages and watermark',
    () async {
      await local.upsertConversations([
        ChatRoomVO(roomId: 'keep-1', roomName: 'keep'),
        ChatRoomVO(roomId: 'stale-1', roomName: 'stale'),
      ]);
      await local.upsertMessages([
        _message(id: 'stale-message-1', roomId: 'stale-1', seq: 1),
      ]);
      await local.updateSyncState(
        scope: 'messages',
        scopeId: 'stale-1',
        lastSyncedAt: DateTime.now(),
        lastSeq: 1,
      );
      remote.rooms = [ChatRoomVO(roomId: 'keep-1', roomName: 'keep')];

      await syncRepository.syncConversations();

      final rooms = await local.getConversations();
      expect(rooms.map((room) => room.roomId), ['keep-1']);
      expect(await local.messageSyncWatermark('stale-1'), 0);
      expect(
        await local.getMessagesForConversation('stale-1', limit: 1000),
        isEmpty,
      );
      final state = await database.syncStateDao.getState('conversations');
      expect(state?.lastSyncedAt, isNotNull);
    },
  );

  test('null remote conversation response never wipes local cache', () async {
    await local.upsertConversations([
      ChatRoomVO(roomId: 'keep-1', roomName: 'keep'),
      ChatRoomVO(roomId: 'stale-1', roomName: 'stale'),
    ]);
    await local.upsertMessages([
      _message(id: 'stale-message-1', roomId: 'stale-1', seq: 1),
    ]);
    await local.updateSyncState(
      scope: 'messages',
      scopeId: 'stale-1',
      lastSyncedAt: DateTime.now(),
      lastSeq: 1,
    );
    remote.rooms = null;

    await syncRepository.syncConversations();

    expect(await local.getConversations(), hasLength(2));
    expect(await local.messageSyncWatermark('stale-1'), 1);
    expect(
      await local.getMessagesForConversation('stale-1', limit: 1000),
      hasLength(1),
    );
    final state = await database.syncStateDao.getState('conversations');
    expect(state?.lastSyncedAt, isNull);
  });
}

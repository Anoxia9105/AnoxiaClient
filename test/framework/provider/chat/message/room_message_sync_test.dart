import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/local_cache/remote_data_source.dart';
import 'package:anoxia/framework/local_cache/sync_repository.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/core/chat_repository_provider.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _OnlineConnectivity extends ConnectivityPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [
    ConnectivityResult.wifi,
  ];
}

class _HistoryRemote extends RemoteDataSource {
  int requests = 0;

  @override
  Future<List<ChatMessage>> fetchMessages(
    String convId, {
    DateTime? since,
    int? lastSeq,
    int? beforeSeq,
    int pageSize = 100,
  }) async {
    requests++;
    return List.generate(
      12,
      (index) => _message(index + 1),
    ).where((message) => message.seq! > (lastSeq ?? 0)).take(pageSize).toList();
  }
}

// 只隔离 WS 订阅；进房同步、本地 SQLite 与增量同步均使用真实实现。
class _RoomMessageServiceWithoutSocket extends ChatMessages {
  @override
  void build() {}
}

ChatMessage _message(int seq) => ChatMessage(
  messageId: 'message-$seq',
  clientMsgId: 'message-$seq',
  roomId: 'room-1',
  senderId: 42,
  messageType: MessageType.text,
  content: 'content-$seq',
  seq: seq,
  timestamp: seq,
);

void main() {
  late AppDatabase database;
  late LocalDataSource local;
  late _HistoryRemote remote;
  late ProviderContainer container;
  late ConnectivityPlatform previousConnectivity;

  setUp(() {
    previousConnectivity = ConnectivityPlatform.instance;
    ConnectivityPlatform.instance = _OnlineConnectivity();
    database = AppDatabase(NativeDatabase.memory());
    local = LocalDataSource(database);
    remote = _HistoryRemote();
    container = ProviderContainer(
      overrides: [
        localDataSourceProvider.overrideWithValue(local),
        chatRepositoryProvider.overrideWithValue(
          SyncRepository(local: local, remote: remote),
        ),
        chatMessagesProvider.overrideWith(_RoomMessageServiceWithoutSocket.new),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
    ConnectivityPlatform.instance = previousConnectivity;
  });

  test('进房时最新 seq 已追平但中间缺消息，仍补齐连续水位后的消息', () async {
    for (final seq in [...List.generate(10, (index) => index + 1), 12]) {
      await local.applyIncomingMessage(_message(seq), incrementUnread: false);
    }
    expect(await local.messageSyncWatermark('room-1'), 10);

    await container
        .read(chatMessagesProvider.notifier)
        .syncRoomMessages('room-1', 12);

    final messages = await local.getMessagesForConversation('room-1');
    expect(
      messages.map((message) => message.seq),
      List.generate(12, (index) => index + 1),
    );
    expect(await local.messageSyncWatermark('room-1'), 12);

    // 补齐后再次进房不应重复请求。
    final requestsAfterSync = remote.requests;
    await container
        .read(chatMessagesProvider.notifier)
        .syncRoomMessages('room-1', 12);
    expect(remote.requests, requestsAfterSync);
  });
}

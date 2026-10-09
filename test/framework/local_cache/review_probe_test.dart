import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/local_cache/sync_repository.dart';
import 'package:anoxia/framework/local_cache/remote_data_source.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _Network implements Connectivity {
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
  @override Future<List<ConnectivityResult>> checkConnectivity() async => [ConnectivityResult.wifi];
}
class _Remote extends RemoteDataSource {
  @override Future<List<ChatRoomVO>?> fetchConversations({DateTime? since}) async => [ChatRoomVO(roomId: 'room', lastReadSeq: 2, unreadCount: 8)];
}
void main() {
  late AppDatabase db;
  late LocalDataSource local;
  setUp(() { db = AppDatabase(NativeDatabase.memory()); local = LocalDataSource(db); });
  tearDown(() => db.close());
  test('撤回仅存在于房间列表中的消息应该清除摘要', () async {
    final message = ChatMessage(messageId: 'recall', roomId: 'room', senderId: 1, content: 'secret', messageType: MessageType.text, seq: 10, timestamp: 1700000000000);
    await local.upsertConversation(ChatRoomVO(roomId: 'room', lastMessage: message));
    await local.applyRecalls(['recall']);
    await local.upsertConversation(ChatRoomVO(roomId: 'room', lastMessage: message));
    expect((await local.getConversations()).single.lastMessage?.messageId, isNot('recall'));
  });
  test('已读ACK后晚到房间列表不应回退已读游标', () async {
    await local.upsertConversation(ChatRoomVO(roomId: 'room', lastReadSeq: 2));
    await local.queueReadCursor('room', 10);
    await local.acknowledgeReadCursor('room', 10);
    final repository = SyncRepository(local: local, remote: _Remote(), connectivity: _Network());
    await repository.syncConversations();
    expect((await local.getConversations()).single.lastReadSeq, 10);
    expect((await local.getConversations()).single.unreadCount, 0);
  });
}

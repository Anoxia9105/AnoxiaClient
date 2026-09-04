import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late LocalDataSource local;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    local = LocalDataSource(database);
    await local.applyIncomingMessage(
      ChatMessage(
        messageId: 'message-30',
        roomId: 'room-1',
        senderId: 42,
        messageType: MessageType.text,
        content: 'hello',
        seq: 30,
        timestamp: 30,
      ),
      incrementUnread: true,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('已读游标和本地已读状态持久化，新数据源实例仍可恢复待发送记录', () async {
    await local.queueReadCursor('room-1', 30);

    final restarted = LocalDataSource(database);
    expect(await restarted.pendingReadCursors(), {'room-1': 30});
    final room = await database.conversationDao.getConversation('room-1');
    expect(room?.lastReadSeq, 30);
    expect(room?.unreadCount, 0);
  });

  test('较小和并发到达的已读游标均不能覆盖较大的待发送游标', () async {
    await local.queueReadCursor('room-1', 30);
    await Future.wait([
      local.queueReadCursor('room-1', 20),
      local.queueReadCursor('room-1', 10),
      local.queueReadCursor('room-1', 25),
    ]);

    expect(await local.pendingReadCursors(), {'room-1': 30});
    final room = await database.conversationDao.getConversation('room-1');
    expect(room?.lastReadSeq, 30);
  });

  test('旧 ACK 不能清除发送期间更新的待发送游标，最新 ACK 可清除', () async {
    await local.queueReadCursor('room-1', 10);
    await local.queueReadCursor('room-1', 30);

    await local.acknowledgeReadCursor('room-1', 10);
    expect(await local.pendingReadCursors(), {'room-1': 30});

    await local.acknowledgeReadCursor('room-1', 30);
    expect(await local.pendingReadCursors(), isEmpty);
    final room = await database.conversationDao.getConversation('room-1');
    expect(room?.lastReadSeq, 30);
  });

  test('ACK 清理只影响对应房间，重复或更大的 ACK 保持幂等', () async {
    await local.applyIncomingMessage(
      ChatMessage(
        messageId: 'room-2-message-20',
        roomId: 'room-2',
        senderId: 42,
        messageType: MessageType.text,
        content: 'hello',
        seq: 20,
        timestamp: 20,
      ),
      incrementUnread: true,
    );
    await local.queueReadCursor('room-1', 10);
    await local.queueReadCursor('room-2', 20);

    await local.acknowledgeReadCursor('room-1', 30);
    await local.acknowledgeReadCursor('room-1', 30);

    expect(await local.pendingReadCursors(), {'room-2': 20});
  });

  test('待发送记录持久化失败时，本地已读更新也必须回滚', () async {
    await database.customStatement('''
      CREATE TRIGGER reject_read_cursor BEFORE INSERT ON sync_states
      WHEN NEW.scope = 'read_cursor_pending'
      BEGIN
        SELECT RAISE(ABORT, 'read cursor storage unavailable');
      END
    ''');

    await expectLater(local.queueReadCursor('room-1', 30), throwsA(anything));

    final room = await database.conversationDao.getConversation('room-1');
    expect(room?.lastReadSeq, 0);
    expect(room?.unreadCount, 1);
    expect(await local.pendingReadCursors(), isEmpty);
  });
}

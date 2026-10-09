import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/chat_contact_vo.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/local_cache/session_epoch.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LocalDataSource source;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    source = LocalDataSource(db);
  });
  tearDown(() => db.close());

  ChatMessage message(
    String id,
    int seq, {
    DeliveryStatus status = DeliveryStatus.sent,
  }) => ChatMessage(
    messageId: id,
    clientMsgId: 'client-$id',
    roomId: 'room',
    senderId: 1,
    seq: seq,
    timestamp: 1700000000000 + seq * 1000,
    messageType: MessageType.text,
    content: id,
    deliveryStatus: status,
  );

  test('旧入站消息落库后保留最新会话摘要', () async {
    await source.applyIncomingMessage(message('new', 2), incrementUnread: true);
    await source.applyIncomingMessage(message('old', 1), incrementUnread: true);
    final room = await db.conversationDao.getConversation('room');
    expect(room!.lastMessageId, 'new');
    expect(room.lastMessagePreview, 'new');
    expect(room.lastMessageSeq, 2);
    expect(await source.getMessageById('old'), isNotNull);
  });

  test('旧 ACK 或失败状态更新不能覆盖最新会话摘要', () async {
    await source.upsertMessage(
      message('old', 1, status: DeliveryStatus.sending),
    );
    await source.applyIncomingMessage(message('new', 2), incrementUnread: true);
    await source.upsertMessage(message('old', 1));
    final room = await db.conversationDao.getConversation('room');
    expect(room!.lastMessageId, 'new');
    expect(room.lastMessagePreview, 'new');
    expect(room.lastMessageSeq, 2);
    await source.upsertMessage(
      message('old', 1, status: DeliveryStatus.failed),
    );
    final afterFailure = await db.conversationDao.getConversation('room');
    expect(afterFailure!.lastMessageId, 'new');
    expect(afterFailure.lastMessageSeq, 2);
  });

  test('删除消息后晚到历史批次不能使消息重新出现', () async {
    final deleted = message('deleted', 1);
    await source.upsertMessage(deleted);
    await source.deleteMessage('deleted');
    await source.upsertMessages([deleted]);
    expect(await source.getMessagesForConversation('room'), isEmpty);
  });

  test('删除消息后晚到入站回显不能使消息重新出现', () async {
    final deleted = message('deleted', 1);
    await source.upsertMessage(deleted);
    await source.deleteMessage('deleted');
    await source.applyIncomingMessage(deleted, incrementUnread: true);
    expect(await source.getMessagesForConversation('room'), isEmpty);
  });

  test('删除先于消息到达时历史批次也不能使消息出现', () async {
    await source.deleteMessage('deleted');
    await source.upsertMessages([message('deleted', 1)]);
    expect(await source.getMessagesForConversation('room'), isEmpty);
  });

  test('联系人权威同步移除列表之外的缓存联系人', () async {
    await source.upsertContacts([
      ChatContactVO(contactId: 1, nickName: '保留'),
      ChatContactVO(contactId: 2, nickName: '已删除'),
    ]);
    await source.replaceContacts([ChatContactVO(contactId: 1, nickName: '更新')]);
    final contacts = await source.getContacts();
    expect(contacts.map((contact) => contact.contactId), [1]);
    expect(contacts.single.nickName, '更新');
  });

  test('联系人权威同步空列表清除所有缓存联系人', () async {
    await source.upsertContacts([ChatContactVO(contactId: 1, nickName: '已删除')]);
    await source.replaceContacts([]);
    expect(await source.getContacts(), isEmpty);
  });

  test('删除最新消息后摘要退回上一条未删除消息', () async {
    await source.upsertMessage(message('old', 1));
    await source.upsertMessage(message('new', 2));
    await source.deleteMessage('new');
    final room = await db.conversationDao.getConversation('room');
    expect(room!.lastMessageId, 'old');
    expect(room.lastMessagePreview, 'old');
    expect(room.lastMessageSeq, 1);
  });

  test('切换账号后旧数据源拒绝晚到消息写入', () async {
    final epoch = SessionEpoch();
    final oldSource = LocalDataSource(db, sessionEpoch: epoch);
    epoch.advance();
    final newSource = LocalDataSource(db, sessionEpoch: epoch);
    await newSource.upsertMessage(message('new-account', 2));
    await expectLater(
      oldSource.applyIncomingMessage(
        message('old-account', 1),
        incrementUnread: true,
      ),
      throwsStateError,
    );
    expect(await newSource.getMessageById('old-account'), isNull);
    expect(
      (await db.conversationDao.getConversation('room'))!.lastMessageId,
      'new-account',
    );
  });

  test('切换账号后旧对账请求不能删除新账号缓存', () async {
    final epoch = SessionEpoch();
    final oldSource = LocalDataSource(db, sessionEpoch: epoch);
    epoch.advance();
    final newSource = LocalDataSource(db, sessionEpoch: epoch);
    await newSource.upsertMessage(message('new-account', 1));
    await newSource.replaceContacts([
      ChatContactVO(contactId: 1, nickName: '新账号好友'),
    ]);
    await expectLater(oldSource.deleteConversationsNotIn([]), throwsStateError);
    await expectLater(oldSource.replaceContacts([]), throwsStateError);
    expect(await newSource.getMessageById('new-account'), isNotNull);
    expect((await newSource.getContacts()).single.nickName, '新账号好友');
  });

  test('已删除的失败消息不能进入待重放队列', () async {
    await source.upsertMessage(
      message('deleted', 0, status: DeliveryStatus.failed),
    );
    await source.deleteMessage('deleted');
    expect(await source.pendingOutgoingMessages(), isEmpty);
  });

  test('即时读取和订阅对乐观消息使用相同的时间顺序', () async {
    await source.upsertMessages([
      message('confirmed', 10),
      message(
        'optimistic',
        0,
        status: DeliveryStatus.sending,
      ).copyWith(timestamp: 1700000020000),
    ]);
    final read = await source.getMessagesForConversation('room');
    final watched = await source.watchMessagesForConversation('room').first;
    expect(read.map((m) => m.messageId), ['confirmed', 'optimistic']);
    expect(watched.map((m) => m.messageId), read.map((m) => m.messageId));
  });

  test('连续同步失败日志保留最近二百条', () async {
    for (var i = 0; i < 205; i++) {
      await source.logSyncFailure(
        scope: 'messages',
        action: 'sync',
        error: 'failure-$i',
      );
    }
    final logs = await db.select(db.syncLogs).get();
    expect(logs.length, lessThanOrEqualTo(200));
  });
}

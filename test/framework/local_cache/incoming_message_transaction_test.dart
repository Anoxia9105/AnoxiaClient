import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('duplicate inbound message does not increment unread twice', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final local = LocalDataSource(database);
    final message = ChatMessage(
      messageId: 'message-1',
      clientMsgId: 'client-1',
      roomId: 'room-1',
      senderId: 42,
      messageType: MessageType.text,
      content: 'hello',
      seq: 1,
      timestamp: 1,
    );

    expect(
      await local.applyIncomingMessage(message, incrementUnread: true),
      true,
    );
    expect(
      await local.applyIncomingMessage(message, incrementUnread: true),
      false,
    );

    final conversation = await database.conversationDao.getConversation(
      'room-1',
    );
    expect(conversation?.unreadCount, 1);
    expect(await local.messageSyncWatermark('room-1'), 1);
  });

  test('bounded watch keeps the newest local pending message', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final local = LocalDataSource(database);
    final history = List.generate(
      120,
      (index) => ChatMessage(
        messageId: 'message-${index + 1}',
        roomId: 'room-2',
        senderId: 42,
        messageType: MessageType.text,
        content: 'message ${index + 1}',
        seq: index + 1,
        timestamp: index + 1,
      ),
    );
    await local.upsertMessages(history);
    await local.upsertMessage(
      ChatMessage(
        messageId: 'pending-message',
        clientMsgId: 'pending-message',
        roomId: 'room-2',
        senderId: 42,
        messageType: MessageType.text,
        content: 'pending',
        seq: 0,
        timestamp: 1000,
        deliveryStatus: DeliveryStatus.sending,
      ),
    );

    final messages = await local
        .watchMessagesForConversation('room-2', limit: 100)
        .first;
    expect(messages, hasLength(100));
    expect(messages.last.messageId, 'pending-message');
    expect(messages.any((message) => message.messageId == 'message-1'), false);
  });

  test('burst local writes remain complete', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final local = LocalDataSource(database);

    await Future.wait(
      List.generate(
        30,
        (index) => local.upsertMessage(
          ChatMessage(
            messageId: 'pending-$index',
            clientMsgId: 'pending-$index',
            roomId: 'room-burst',
            senderId: 42,
            messageType: MessageType.text,
            content: 'message $index',
            seq: 0,
            timestamp: 1000 + index,
            deliveryStatus: DeliveryStatus.sending,
          ),
        ),
      ),
    );

    final messages = await local.getMessagesForConversation(
      'room-burst',
      limit: 50,
    );
    expect(messages, hasLength(30));
    expect(
      messages.map((message) => message.messageId).toSet(),
      {for (var index = 0; index < 30; index++) 'pending-$index'},
    );
  });
}

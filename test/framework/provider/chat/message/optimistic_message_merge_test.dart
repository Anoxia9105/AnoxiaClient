import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ChatMessage message(
    String id,
    int timestamp, {
    DeliveryStatus status = DeliveryStatus.sent,
  }) {
    return ChatMessage(
      messageId: id,
      clientMsgId: id,
      roomId: 'room-1',
      senderId: 1,
      messageType: MessageType.text,
      content: id,
      timestamp: timestamp,
      deliveryStatus: status,
    );
  }

  test('optimistic messages appear immediately in timestamp order', () {
    final merged = mergeOptimisticMessages(
      [message('persisted', 100)],
      [
        message('pending-2', 300, status: DeliveryStatus.sending),
        message('pending-1', 200, status: DeliveryStatus.sending),
      ],
    );

    expect(merged.map((item) => item.messageId), [
      'persisted',
      'pending-1',
      'pending-2',
    ]);
  });

  test('persisted rows replace matching optimistic rows', () {
    final persisted = message('same-id', 100);
    final optimistic = message('same-id', 100, status: DeliveryStatus.sending);

    final merged = mergeOptimisticMessages([persisted], [optimistic]);

    expect(merged, hasLength(1));
    expect(merged.single.deliveryStatus, DeliveryStatus.sent);
  });

  test('optimistic row is cleared only after a matching DB snapshot', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(optimisticRoomMessagesProvider.notifier);
    final pending = message('pending-id', 100, status: DeliveryStatus.sending);

    notifier.upsert(pending);
    notifier.removePersisted([message('other-id', 90)]);
    expect(container.read(optimisticRoomMessagesProvider)['room-1'], [pending]);

    notifier.removePersisted([message('pending-id', 100)]);
    expect(
      container.read(optimisticRoomMessagesProvider).containsKey('room-1'),
      false,
    );
  });
}

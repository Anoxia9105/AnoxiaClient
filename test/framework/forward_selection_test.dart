import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/message/forward_selection_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ChatMessage message(
    int index, {
    String room = 'source',
    int seq = 1,
    DeliveryStatus status = DeliveryStatus.sent,
    MessageType type = MessageType.text,
  }) => ChatMessage(
    messageId: 'm$index',
    roomId: room,
    seq: seq,
    deliveryStatus: status,
    messageType: type,
  );

  test('只能选择已确认的用户消息', () {
    expect(canForwardMessage(message(1, seq: 0)), isFalse);
    expect(
      canForwardMessage(message(1, status: DeliveryStatus.sending)),
      isFalse,
    );
    expect(
      canForwardMessage(message(1, status: DeliveryStatus.failed)),
      isFalse,
    );
    expect(canForwardMessage(message(1, type: MessageType.system)), isFalse);
    expect(canForwardMessage(message(1)), isTrue);
  });
  test('限制同房 50 条，撤回移除，取消重置选择', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = forwardSelectionControllerProvider('source');
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    final controller = container.read(provider.notifier);
    controller.start(message(0));
    expect(controller.toggle(message(100, room: 'other')), isFalse);
    for (var i = 1; i < 50; i++) {
      expect(controller.toggle(message(i)), isTrue);
    }
    expect(controller.toggle(message(50)), isFalse);
    controller.remove('m0');
    expect(container.read(provider).messages.length, 49);
    expect(controller.toggle(message(50)), isTrue);
    controller.clear();
    expect(container.read(provider).active, isFalse);
    expect(container.read(provider).messages, isEmpty);
  });
}

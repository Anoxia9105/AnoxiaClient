import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('message window is bounded and can be reset per room', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(chatMessageWindowLimitsProvider.notifier);

    expect(notifier.limitFor('room-a'), 100);
    expect(notifier.expand('room-a', 50), isTrue);
    expect(notifier.limitFor('room-a'), 150);

    for (var i = 0; i < 20; i++) {
      notifier.expand('room-a', 100);
    }
    expect(notifier.limitFor('room-a'), 1000);
    expect(notifier.expand('room-a'), isFalse);

    notifier.reset('room-a');
    expect(notifier.limitFor('room-a'), 100);
  });
}

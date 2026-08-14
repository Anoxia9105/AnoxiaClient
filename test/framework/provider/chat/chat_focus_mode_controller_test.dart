import 'package:anoxia/framework/provider/chat/chat_focus_mode_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldUseChatFocusMode', () {
    test(
      'requires the setting, a wide layout, the chat tab and an active room',
      () {
        expect(
          shouldUseChatFocusMode(
            enabled: true,
            isWideLayout: true,
            currentIndex: 0,
            activeRoomId: 'room-1',
          ),
          isTrue,
        );

        expect(
          shouldUseChatFocusMode(
            enabled: false,
            isWideLayout: true,
            currentIndex: 0,
            activeRoomId: 'room-1',
          ),
          isFalse,
        );
        expect(
          shouldUseChatFocusMode(
            enabled: true,
            isWideLayout: false,
            currentIndex: 0,
            activeRoomId: 'room-1',
          ),
          isFalse,
        );
        expect(
          shouldUseChatFocusMode(
            enabled: true,
            isWideLayout: true,
            currentIndex: 1,
            activeRoomId: 'room-1',
          ),
          isFalse,
        );
        expect(
          shouldUseChatFocusMode(
            enabled: true,
            isWideLayout: true,
            currentIndex: 0,
            activeRoomId: null,
          ),
          isFalse,
        );
      },
    );

    test('treats an empty room id as no active conversation', () {
      expect(
        shouldUseChatFocusMode(
          enabled: true,
          isWideLayout: true,
          currentIndex: 0,
          activeRoomId: '',
        ),
        isFalse,
      );
    });
  });
}

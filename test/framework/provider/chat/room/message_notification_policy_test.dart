import 'package:anoxia/framework/provider/chat/room/message_notification_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldShowLocalMessageNotification', () {
    test('suppresses the active room while the web tab is visible', () {
      expect(
        shouldShowLocalMessageNotification(
          isSelfMessage: false,
          isCallSystemMessage: false,
          isCurrentRoom: true,
          isDoNotDisturb: false,
          isMobile: false,
          isAppForeground: true,
          isWeb: true,
        ),
        isFalse,
      );
    });

    test('notifies for the active room while the web tab is hidden', () {
      expect(
        shouldShowLocalMessageNotification(
          isSelfMessage: false,
          isCallSystemMessage: false,
          isCurrentRoom: true,
          isDoNotDisturb: false,
          isMobile: false,
          isAppForeground: false,
          isWeb: true,
        ),
        isTrue,
      );
    });

    test('keeps the active-room behavior unchanged on other platforms', () {
      expect(
        shouldShowLocalMessageNotification(
          isSelfMessage: false,
          isCallSystemMessage: false,
          isCurrentRoom: true,
          isDoNotDisturb: false,
          isMobile: false,
          isAppForeground: false,
          isWeb: false,
        ),
        isFalse,
      );
    });

    test('keeps existing message suppression rules', () {
      bool evaluate({
        bool isSelfMessage = false,
        bool isCallSystemMessage = false,
        bool isDoNotDisturb = false,
        bool isMobile = false,
        bool isAppForeground = false,
      }) {
        return shouldShowLocalMessageNotification(
          isSelfMessage: isSelfMessage,
          isCallSystemMessage: isCallSystemMessage,
          isCurrentRoom: false,
          isDoNotDisturb: isDoNotDisturb,
          isMobile: isMobile,
          isAppForeground: isAppForeground,
          isWeb: true,
        );
      }

      expect(evaluate(isSelfMessage: true), isFalse);
      expect(evaluate(isCallSystemMessage: true), isFalse);
      expect(evaluate(isDoNotDisturb: true), isFalse);
      expect(evaluate(isMobile: true, isAppForeground: true), isFalse);
    });
  });
}

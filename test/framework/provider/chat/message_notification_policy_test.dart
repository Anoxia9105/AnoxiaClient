import 'package:anoxia/framework/provider/chat/room/message_notification_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool notify({
    bool foreground = false,
    bool self = false,
    bool muted = false,
    bool call = false,
  }) => shouldShowLocalMessageNotification(
    isSelfMessage: self,
    isCallSystemMessage: call,
    isCurrentRoom: true,
    isDoNotDisturb: muted,
    isMobile: false,
    isAppForeground: foreground,
    isWeb: false,
  );

  test('桌面选中房间最小化、隐藏或失焦后仍应通知', () => expect(notify(), isTrue));
  test('前台正在查看当前房间不通知', () => expect(notify(foreground: true), isFalse));
  test('后台仍尊重免打扰、自己消息和通话系统消息过滤', () {
    expect(notify(muted: true), isFalse);
    expect(notify(self: true), isFalse);
    expect(notify(call: true), isFalse);
  });
}

import 'package:anoxia/framework/provider/chat/room/message_notification_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool notify({
    bool foreground = false,
    bool self = false,
    bool muted = false,
    bool call = false,
    bool currentRoom = true,
    bool mobile = false,
    bool web = false,
  }) => shouldShowLocalMessageNotification(
    isSelfMessage: self,
    isCallSystemMessage: call,
    isCurrentRoom: currentRoom,
    isDoNotDisturb: muted,
    isMobile: mobile,
    isAppForeground: foreground,
    isWeb: web,
  );

  test('桌面选中房间最小化、隐藏或失焦后仍应通知', () => expect(notify(), isTrue));
  test('前台正在查看当前房间不通知', () => expect(notify(foreground: true), isFalse));
  test('后台仍尊重免打扰、自己消息和通话系统消息过滤', () {
    expect(notify(muted: true), isFalse);
    expect(notify(self: true), isFalse);
    expect(notify(call: true), isFalse);
  });

  group('DND（免打扰）矩阵', () {
    test('免打扰房间在未选中/后台时静默，是最强过滤之一', () {
      expect(notify(muted: true, currentRoom: false), isFalse);
      expect(notify(muted: true, foreground: true, currentRoom: false), isFalse);
    });

    test('免打扰不能掩盖其它过滤的反向例：非 DND 同参数下可通知', () {
      expect(notify(currentRoom: false), isTrue);
      expect(notify(foreground: true, currentRoom: false), isTrue);
    });

    test('免打扰对象是房间维度：选中房间与否不影响 DND 判定', () {
      expect(notify(muted: true), isFalse);
    });

    test('移动端前台：无论 DND 与否都不弹本地通知（策略末端统一压制）', () {
      expect(notify(mobile: true, web: false, foreground: true), isFalse);
      expect(notify(mobile: true, web: false, foreground: true, muted: true), isFalse);
    });

    test('移动端后台：仍视为「正在查看当前房间」，非 DND 房间切走才可通知', () {
      // 原语义：mobile + currentRoom 视为活跃查看（与前台无关），一律静默；
      // 切到别的会话列表（非当前房间）才弹。
      expect(notify(mobile: true, web: false, foreground: false, muted: true), isFalse);
      expect(notify(mobile: true, web: false, foreground: false), isFalse);
      expect(notify(mobile: true, web: false, foreground: false, currentRoom: false), isTrue);
      expect(
        notify(mobile: true, web: false, foreground: false, currentRoom: false, muted: true),
        isFalse,
      );
    });

    test('Web 选中标签页但已切走后台：仍应通知', () {
      expect(notify(web: true, mobile: false, foreground: false), isTrue);
    });
  });
}

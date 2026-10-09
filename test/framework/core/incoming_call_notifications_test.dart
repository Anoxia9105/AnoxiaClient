import 'dart:async';

import 'package:anoxia/framework/core/incoming_call_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late IncomingCallNotifications notifications;
  late List<String> events;
  setUp(() {
    notifications = IncomingCallNotifications();
    events = [];
  });

  Future<void> show(
    String id, {
    Future<bool> Function()? prepare,
    Future<void> Function()? present,
  }) => notifications.show(
    inviteId: id,
    prepare: prepare ?? () async => true,
    present:
        present ??
        () async {
          events.add('show:$id');
        },
    dismiss: () async {
      events.add('cancel:$id');
    },
  );
  Future<void> cancel(String id) => notifications.cancel(id, () async {
    events.add('cancel:$id');
  });

  test('收到邀请即可显示，同一邀请只通知一次，下一通呼叫正常提醒', () async {
    await show('first');
    await show('first');
    expect(events, ['show:first']);
    await cancel('first');
    await show('second');
    expect(events, ['show:first', 'cancel:first', 'show:second']);
  });

  test('准备通知期间接听或取消，不再弹出迟到通知', () async {
    final preparing = Completer<bool>();
    final pending = show('first', prepare: () => preparing.future);
    await cancel('first');
    preparing.complete(true);
    await pending;
    expect(events, ['cancel:first']);
  });

  test('原生显示尚未完成时取消，完成后补清理', () async {
    final presenting = Completer<void>();
    final started = Completer<void>();
    final pending = show(
      'first',
      present: () async {
        started.complete();
        await presenting.future;
        events.add('show:first');
      },
    );
    await started.future;
    await cancel('first');
    presenting.complete();
    await pending;
    expect(events, ['cancel:first', 'show:first', 'cancel:first']);
  });

  test('重复邀请不启动第二次准备，取消旧邀请不影响新来电', () async {
    final preparing = Completer<bool>();
    final pending = show('first', prepare: () => preparing.future);
    await show('first');
    await cancel('first');
    await show('second');
    preparing.complete(true);
    await pending;
    expect(events, ['cancel:first', 'show:second']);
  });

  test('权限不可用时不显示，授权后允许重新尝试', () async {
    await show('first', prepare: () async => false);
    expect(events, isEmpty);
    await show('first');
    expect(events, ['show:first']);
  });
}

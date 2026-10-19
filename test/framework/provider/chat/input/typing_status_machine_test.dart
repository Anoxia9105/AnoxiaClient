// TypingStatusMachine（正在输入状态机）单元测试。
//
// 锁定 ChatInputController 原实现的行为：
// - 内容出现 → 发送「开始」；2 秒无变更 → 自动发送「结束」；
// - 成功发出「开始」后 3 秒内不重复发送（节流），期间回落为停止重试；
// - 回调返回 false（对方离线/房间未同步）时不武装节流，每次变更都可重试；
// - 移动端纯文本路径：内容清空立即发送「结束」；富文本路径等 idle 到点；
// - resetSilently（发送成功清空输入框）不发「结束」且取消 idle。
import 'package:anoxia/framework/provider/chat/input/typing_status_machine.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('内容出现立即发送「开始」，2 秒无变更自动发送「结束」且只发一次', () {
    fakeAsync((async) {
      final sent = <bool>[];
      final machine = TypingStatusMachine(trySend: (v) {
        sent.add(v);
        return true;
      });

      machine.onTextChanged(hasContent: true);
      expect(sent, [true]);
      expect(machine.isTyping, isTrue);

      async.elapse(const Duration(seconds: 2));
      expect(sent, [true, false]);
      expect(machine.isTyping, isFalse);

      // 已结束后不会再重复发送
      async.elapse(const Duration(seconds: 10));
      expect(sent, [true, false]);

      machine.dispose();
    });
  });

  test('持续输入不触发 idle 结束；「开始」按 3s 节流周期重发', () {
    fakeAsync((async) {
      final sent = <bool>[];
      final machine = TypingStatusMachine(trySend: (v) {
        sent.add(v);
        return true;
      });

      // t=0 首次开始
      machine.onTextChanged(hasContent: true);
      // t=1, t=2 变更：idle 不断被重置，节流期内不重复开始
      for (var i = 1; i < 3; i++) {
        async.elapse(const Duration(seconds: 1));
        machine.onTextChanged(hasContent: true);
      }
      expect(sent, [true]);

      // t=3：节流解除，下一次变更重发「开始」（持续长输入场景的周期性心跳暗示）
      async.elapse(const Duration(seconds: 1));
      machine.onTextChanged(hasContent: true);
      expect(sent, [true, true]);

      machine.dispose();
    });
  });

  test('rich 路径清空不立即结束，等 idle 到点才发「结束」', () {
    fakeAsync((async) {
      final sent = <bool>[];
      final machine = TypingStatusMachine(trySend: (v) {
        sent.add(v);
        return true;
      });

      machine.onTextChanged(hasContent: true);
      async.elapse(const Duration(milliseconds: 500));
      machine.onTextChanged(hasContent: false);
      expect(sent, [true]);

      // 从清空时刻起的 2 秒 idle 到点后发送停止
      async.elapse(const Duration(seconds: 2));
      expect(sent, [true, false]);

      machine.dispose();
    });
  });

  test('移动端纯文本路径：内容清空立即发送「结束」，不等 idle', () {
    fakeAsync((async) {
      final sent = <bool>[];
      final machine = TypingStatusMachine(trySend: (v) {
        sent.add(v);
        return true;
      });

      machine.onPlainTextChanged(hasContent: true);
      async.elapse(const Duration(milliseconds: 500));
      machine.onPlainTextChanged(hasContent: false);
      expect(sent, [true, false]);

      // 之后的 idle 计时不会重复发送
      async.elapse(const Duration(seconds: 10));
      expect(sent, [true, false]);

      machine.dispose();
    });
  });

  test('「结束」到点后，节流也被清除 —— 之后的「开始」不再被压制', () {
    fakeAsync((async) {
      final sent = <bool>[];
      final machine = TypingStatusMachine(trySend: (v) {
        sent.add(v);
        return true;
      });

      machine.onTextChanged(hasContent: true); // t=0 start
      async.elapse(const Duration(seconds: 2)); // idle stop（顺带清理节流）
      expect(sent, [true, false]);

      machine.onTextChanged(hasContent: true); // t≈2 new start（< 原节流 3s 窗口）
      expect(sent, [true, false, true]);

      machine.dispose();
    });
  });

  test('回调返回 false（未发出）不武装节流：每次变更都会重试', () {
    fakeAsync((async) {
      final attempts = <bool>[];
      final machine = TypingStatusMachine(trySend: (v) {
        attempts.add(v);
        return false; // 模拟对方离线/房间未同步
      });

      machine.onTextChanged(hasContent: true);
      async.elapse(const Duration(milliseconds: 500));
      machine.onTextChanged(hasContent: true);
      machine.onTextChanged(hasContent: true);
      expect(attempts, [true, true, true]);

      // idle 到点仍会尝试发送「结束」，同样不触发节流状态变更
      async.elapse(const Duration(seconds: 2));
      expect(attempts, [true, true, true, false]);

      machine.dispose();
    });
  });

  test('resetSilently：不发「结束」、取消 idle，节流随时间自然过期', () {
    fakeAsync((async) {
      final sent = <bool>[];
      final machine = TypingStatusMachine(trySend: (v) {
        sent.add(v);
        return true;
      });

      machine.onTextChanged(hasContent: true); // t=0 start
      async.elapse(const Duration(milliseconds: 500));
      machine.resetSilently(); // 发送成功后清空输入框：不应发送结束
      expect(sent, [true]);

      async.elapse(const Duration(seconds: 10));
      expect(sent, [true]); // idle 已取消，无停止帧

      async.elapse(const Duration(seconds: 3)); // 距 t=0 已超 3s，节流过期
      machine.onTextChanged(hasContent: true);
      expect(sent, [true, true]);

      machine.dispose();
    });
  });

  test('dispose 后定时器全部取消，无后续发送且不抛异常', () {
    fakeAsync((async) {
      final sent = <bool>[];
      final machine = TypingStatusMachine(trySend: (v) {
        sent.add(v);
        return true;
      });

      machine.onTextChanged(hasContent: true);
      machine.dispose();
      async.elapse(const Duration(seconds: 30));
      expect(sent, [true]);
    });
  });
}

import 'dart:async';
import 'package:anoxia/framework/provider/chat/call/call_connection_warmup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('并发振铃只做一次预热，连接不等待慢预热', () async {
    final pending = Completer<void>();
    var attempts = 0;
    final warmup = CallConnectionWarmup(() {
      attempts++;
      return pending.future;
    });
    warmup.start();
    warmup.start();
    expect(attempts, 1);
    expect(warmup.isReady, isFalse);
    pending.complete();
    await pending.future;
    await Future<void>.delayed(Duration.zero);
    expect(warmup.isReady, isTrue);
    warmup.start();
    expect(attempts, 1);
  });
  test('预热失败不阻断通话，下次允许重试', () async {
    var attempts = 0;
    final warmup = CallConnectionWarmup(() async {
      attempts++;
      if (attempts == 1) throw StateError('网络不可用');
    });
    warmup.start();
    await Future<void>.delayed(Duration.zero);
    expect(warmup.isReady, isFalse);
    warmup.start();
    await Future<void>.delayed(Duration.zero);
    expect(warmup.isReady, isTrue);
    expect(attempts, 2);
  });
}

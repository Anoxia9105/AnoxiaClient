import 'dart:async';

import 'package:anoxia/framework/provider/chat/call/call_media_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('挂断等待进行中的建连结束，且不再启动后续媒体', () async {
    final connected = Completer<void>();
    var microphoneStarted = false;
    var disposed = false;
    final lifecycle = CallMediaLifecycle(dispose: () async => disposed = true);
    final connecting = lifecycle.run(() async {
      await connected.future;
      lifecycle.ensureOpen();
      microphoneStarted = true;
    });
    final failedConnection = expectLater(connecting, throwsStateError);

    final closing = lifecycle.close();
    expect(identical(closing, lifecycle.close()), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(disposed, isFalse);

    connected.complete();
    await failedConnection;
    await closing;
    expect(microphoneStarted, isFalse);
    expect(disposed, isTrue);
  });

  test('挂断等待所有设备操作结束，并只释放一次', () async {
    final camera = Completer<void>();
    final microphone = Completer<void>();
    var disposals = 0;
    final lifecycle = CallMediaLifecycle(
      dispose: () async {
        disposals++;
      },
    );
    final cameraOperation = lifecycle.run(() => camera.future);
    final microphoneOperation = lifecycle.run(() => microphone.future);
    final closing = lifecycle.close();
    camera.complete();
    await cameraOperation;
    expect(disposals, 0);
    microphone.complete();
    await microphoneOperation;
    await closing;
    await lifecycle.close();
    expect(disposals, 1);
    await expectLater(lifecycle.run(() async {}), throwsStateError);
  });

  test('初始化失败后仍可完成资源清理', () async {
    var disposed = false;
    final lifecycle = CallMediaLifecycle(dispose: () async => disposed = true);
    await expectLater(
      lifecycle.run(() async => throw StateError('连接失败')),
      throwsStateError,
    );
    await lifecycle.close();
    expect(disposed, isTrue);
  });

  test('释放失败传播给关窗调用方，不能被视为清理成功', () async {
    final lifecycle = CallMediaLifecycle(
      dispose: () async => throw StateError('原生资源释放失败'),
    );
    final closing = lifecycle.close();
    await expectLater(closing, throwsStateError);
    expect(identical(closing, lifecycle.close()), isTrue);
  });
}

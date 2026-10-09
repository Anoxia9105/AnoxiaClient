import 'package:anoxia/framework/provider/chat/call/call_initialization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('摄像头故障不影响语音，麦克风优先就绪', () async {
    var microphoneReady = false;
    final errors = <Object>[];
    await initializeCallMedia(
      microphone: () async => microphoneReady = true,
      camera: () async {
        expect(microphoneReady, isTrue);
        throw StateError('摄像头被占用');
      },
      ensureOpen: () {},
      onError: (error, _) => errors.add(error),
    );
    expect(microphoneReady, isTrue);
    expect(errors, hasLength(1));
  });

  test('麦克风故障仍允许摄像头启动', () async {
    var cameraReady = false;
    await initializeCallMedia(
      microphone: () async => throw StateError('无麦克风'),
      camera: () async => cameraReady = true,
      ensureOpen: () {},
      onError: (_, _) {},
    );
    expect(cameraReady, isTrue);
  });

  test('退出期间停止初始化，不把生命周期关闭当成设备故障', () async {
    var cameraReady = false;
    await expectLater(
      initializeCallMedia(
        microphone: () async {},
        camera: () async => cameraReady = true,
        ensureOpen: () => throw StateError('已退出'),
        onError: (_, _) => fail('不应吞掉退出信号'),
      ),
      throwsStateError,
    );
    expect(cameraReady, isFalse);
  });
}

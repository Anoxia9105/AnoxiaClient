// Web 端 pip（画中画）桩。
//
// 浏览器端不支持原生画中画 API，所有方法均为 no-op。
// 类名 / 方法签名尽量与真实 `pip` 包保持一致，以便调用点编译通过。
class PipOptions {
  final int aspectRatioX;
  final int aspectRatioY;
  final bool autoEnterEnabled;
  final bool seamlessResizeEnabled;

  const PipOptions({
    this.aspectRatioX = 1,
    this.aspectRatioY = 1,
    this.autoEnterEnabled = false,
    this.seamlessResizeEnabled = false,
  });
}

enum PipState { pipStateStarted, pipStateStopped, pipStateFailed }

class PipStateChangedObserver {
  final void Function(PipState state, Object? error)? onPipStateChanged;
  const PipStateChangedObserver({this.onPipStateChanged});
}

class Pip {
  Future<bool> isAvailable() async => false;
  Future<bool> isSupported() async => false;
  Future<void> setup(PipOptions options) async {}
  Future<void> registerStateChangedObserver(
    PipStateChangedObserver observer,
  ) async {}
  Future<void> unregisterStateChangedObserver() async {}
  Future<bool> isActive() async => false;
  Future<bool> start() async => false;
  Future<bool> enterPipMode() async => false;
  Future<bool> exitPipMode() async => false;
  Future<void> dispose() async {}
}

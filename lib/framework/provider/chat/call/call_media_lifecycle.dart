import 'dart:async';

/// 关窗前的媒体屏障：停止接收新操作，等待已启动的操作，再释放原生资源。
/// 超时不会取消 Dart Future，因此这里不能用 timeout 提前放行关窗。
class CallMediaLifecycle {
  CallMediaLifecycle({required Future<void> Function() dispose})
    : _dispose = dispose;

  final Future<void> Function() _dispose;
  final Set<Future<void>> _pending = {};
  Future<void>? _closeFuture;
  bool _closing = false;

  bool get isClosing => _closing;

  void ensureOpen() {
    if (_closing) throw StateError('通话正在结束');
  }

  Future<T> run<T>(Future<T> Function() operation) async {
    ensureOpen();
    // 在调用 operation 前登记，避免同步回调重入 close 时遗漏当前操作。
    final done = Completer<void>();
    _pending.add(done.future);
    try {
      return await operation();
    } finally {
      _pending.remove(done.future);
      done.complete();
    }
  }

  Future<void> close() {
    _closing = true;
    return _closeFuture ??= _close();
  }

  Future<void> _close() async {
    await Future.wait(_pending.toList());
    await _dispose();
  }
}

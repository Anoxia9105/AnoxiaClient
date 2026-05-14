import 'dart:async';

/// 防抖工具类
///
/// 用于限制高频调用场景，在最后一次调用后延迟执行。
/// 常用于搜索输入、窗口 resize 等需要等待用户停止操作后执行的场景。
class Debouncer {
  /// 防抖延迟时间
  final Duration delay;

  Timer? _timer;

  Debouncer({required this.delay});

  /// 执行防抖操作
  ///
  /// 如果在 [delay] 时间内再次调用，会取消之前的定时器并重新计时
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// 释放资源
  void dispose() {
    _timer?.cancel();
  }
}

// 「正在输入」状态机：纯状态逻辑，可被 fake_async 单测锁定。
//
// 职责边界：
// - 本机负责 _isTyping 标志、2 秒无输入自动结束、3 秒重复「开始」节流；
// - 房间/成员/在线校验等真实发送前置条件由调用方在 [trySend] 回调里完成，
//   返回 false 表示本次实际未发出（例如对方离线），此时状态机不上节流，
//   后续输入会继续重试 —— 与 ChatInputController 原实现逐分支等价。
import 'dart:async';

/// 「正在输入」节流与自动结束状态机。
class TypingStatusMachine {
  TypingStatusMachine({
    required bool Function(bool isTyping) trySend,
    this.idleStopAfter = const Duration(seconds: 2),
    this.repeatThrottleFor = const Duration(seconds: 3),
  }) : _trySend = trySend;

  /// 状态切换发送回调。返回 true 表示通道已受理。
  ///
  /// 返回 false 时（未上线/房间未同步/对方离线）状态机不做任何
  /// 节流状态变更 —— 与原实现「校验失败直接 return、节流定时器不触碰」一致。
  final bool Function(bool isTyping) _trySend;

  /// 无输入多久后自动发送结束状态。
  final Duration idleStopAfter;

  /// 成功发出「开始输入」后，多久内不重复发送。
  final Duration repeatThrottleFor;

  Timer? _idleTimer;
  Timer? _repeatGuard;
  bool _isTyping = false;
  bool _startThrottled = false;

  /// 当前是否处于「正在输入」状态。
  bool get isTyping => _isTyping;

  /// 富文本编辑器文本变化回调。
  ///
  /// [hasContent] 由调用方按编辑器口径计算（如文档长度 > 终止换行）。
  void onTextChanged({required bool hasContent}) =>
      _handle(hasContent: hasContent, immediateStopWhenEmpty: false);

  /// 移动端纯文本输入路径：内容清空时立即发送结束状态（不等 idle 超时）。
  void onPlainTextChanged({required bool hasContent}) =>
      _handle(hasContent: hasContent, immediateStopWhenEmpty: true);

  void _handle({
    required bool hasContent,
    required bool immediateStopWhenEmpty,
  }) {
    if (hasContent) {
      _isTyping = true;
      _attempt(true);
    }

    _idleTimer?.cancel();
    _idleTimer = Timer(idleStopAfter, () {
      if (_isTyping) {
        _isTyping = false;
        _attempt(false);
      }
    });

    if (immediateStopWhenEmpty && !hasContent && _isTyping) {
      _isTyping = false;
      _attempt(false);
    }
  }

  /// 静默复位（如发送成功后清空输入框）：不发结束状态。
  void resetSilently() {
    _isTyping = false;
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  /// 释放内部定时器。
  void dispose() {
    _idleTimer?.cancel();
    _repeatGuard?.cancel();
    _idleTimer = null;
    _repeatGuard = null;
  }

  void _attempt(bool isTyping) {
    if (isTyping && _startThrottled) return;

    final delivered = _trySend(isTyping);
    if (!delivered) return;

    // 与原实现一致：只有发送路径真正走到通道时才触碰节流定时器。
    _repeatGuard?.cancel();
    if (isTyping) {
      _startThrottled = true;
      _repeatGuard = Timer(repeatThrottleFor, () => _startThrottled = false);
    } else {
      _startThrottled = false;
      _repeatGuard = null;
    }
  }
}

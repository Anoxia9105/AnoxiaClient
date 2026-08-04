// 原生平台跨标签页会话同步桩。
//
// 桌面/移动端多窗口是独立进程，不共享 localStorage/IndexedDB，不存在
// 跨标签页会话错位问题，此桩供调用点统一引用而不必区分平台。
import 'dart:async';

/// 跨标签页会话事件动作
enum CrossTabAuthAction { login, logout }

/// 跨标签页会话事件
class CrossTabAuthEvent {
  const CrossTabAuthEvent({required this.action, this.userId});

  final CrossTabAuthAction action;
  final int? userId;
}

/// 跨标签页会话同步器
class CrossTabSessionSync {
  CrossTabSessionSync._internal();

  static final CrossTabSessionSync instance = CrossTabSessionSync._internal();

  final StreamController<CrossTabAuthEvent> _controller =
      StreamController<CrossTabAuthEvent>.broadcast();

  /// 空事件流（原生平台永不触发）
  Stream<CrossTabAuthEvent> get events => _controller.stream;

  void broadcastLogin(int? userId) {}

  void broadcastLogout(int? userId) {}

  void reload() {}
}

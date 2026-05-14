enum WsStatus { connecting, connected, disconnected, error }

/// WebSocket 连接状态
///
/// 用于 UI 层展示连接状态和错误信息
class WsState {
  /// 当前连接状态
  final WsStatus status;

  /// 错误信息（连接失败时填充）
  final String? error;

  WsState({required this.status, this.error});
}

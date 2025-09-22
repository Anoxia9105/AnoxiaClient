/// WebSocket连接状态枚举
enum WebSocketState {
  /// 未连接
  disconnected,
  /// 连接中
  connecting,
  /// 已连接
  connected,
  /// 重连中
  reconnecting,
  /// 连接失败
  failed,
}
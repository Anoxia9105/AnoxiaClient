enum WsStatus { connecting, connected, disconnected, error }
//定义状态类
class WsState {
  final WsStatus status;
  final String? error;

  WsState({required this.status, this.error});
}
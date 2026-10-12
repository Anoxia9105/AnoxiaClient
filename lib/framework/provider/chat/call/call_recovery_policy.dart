import 'package:livekit_client/livekit_client.dart';

/// LiveKit 自身重连已放弃后，限制应用层额外恢复次数。
/// 不持有计时器，调用方负责等待退避时长并确认通话仍然有效。
class CallRecoveryPolicy {
  static const _delays = [Duration(seconds: 2), Duration(seconds: 5)];
  static const _stableConnection = Duration(seconds: 30);
  static const _recoverableReasons = {
    DisconnectReason.signalingConnectionFailure,
    DisconnectReason.disconnected,
    DisconnectReason.signalClose,
    DisconnectReason.connectionTimeout,
    DisconnectReason.mediaFailure,
    DisconnectReason.reconnectAttemptsExceeded,
    DisconnectReason.unknown,
  };

  int _attempts = 0;
  DateTime? _connectedAt;

  /// 仅在真正建立连接时调用，短暂重连成功不会立即重置预算。
  void markConnected(DateTime now) {
    _connectedAt = now;
  }

  /// 断开时消费一次恢复预算；返回 null 表示应保持终止状态。
  Duration? nextDelay(DisconnectReason? reason, {required DateTime now}) {
    final connectedAt = _connectedAt;
    _connectedAt = null;
    if (connectedAt != null &&
        now.difference(connectedAt) >= _stableConnection) {
      _attempts = 0;
    }
    if (!_recoverableReasons.contains(reason ?? DisconnectReason.unknown) ||
        _attempts >= _delays.length) {
      return null;
    }
    return _delays[_attempts++];
  }

  /// 显式发起新通话或手动重新尝试时清理上一轮预算。
  void reset() {
    _attempts = 0;
    _connectedAt = null;
  }
}

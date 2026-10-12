import 'package:anoxia/framework/provider/chat/call/call_recovery_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart';

void main() {
  final now = DateTime(2026, 10, 10);

  test('只对网络或媒体故障允许 SDK 放弃后的额外恢复', () {
    const recoverable = {
      DisconnectReason.signalingConnectionFailure,
      DisconnectReason.disconnected,
      DisconnectReason.signalClose,
      DisconnectReason.connectionTimeout,
      DisconnectReason.mediaFailure,
      DisconnectReason.reconnectAttemptsExceeded,
      DisconnectReason.unknown,
    };
    for (final reason in DisconnectReason.values) {
      final policy = CallRecoveryPolicy();
      expect(
        policy.nextDelay(reason, now: now),
        recoverable.contains(reason) ? const Duration(seconds: 2) : isNull,
        reason: reason.name,
      );
    }
  });

  test('未知原因按网络故障尝试恢复', () {
    expect(
      CallRecoveryPolicy().nextDelay(null, now: now),
      const Duration(seconds: 2),
    );
  });

  test('额外恢复仅两次，分别退避 2 秒和 5 秒', () {
    final policy = CallRecoveryPolicy();
    expect(
      policy.nextDelay(DisconnectReason.disconnected, now: now),
      const Duration(seconds: 2),
    );
    expect(
      policy.nextDelay(DisconnectReason.mediaFailure, now: now),
      const Duration(seconds: 5),
    );
    expect(policy.nextDelay(DisconnectReason.unknown, now: now), isNull);
  });

  test('连接未稳定 30 秒不会清零恢复预算，避免反复建连循环', () {
    final policy = CallRecoveryPolicy();
    policy.nextDelay(DisconnectReason.disconnected, now: now);
    policy.markConnected(now);
    expect(
      policy.nextDelay(
        DisconnectReason.disconnected,
        now: now.add(const Duration(seconds: 29)),
      ),
      const Duration(seconds: 5),
    );
    policy.markConnected(now.add(const Duration(seconds: 29)));
    expect(
      policy.nextDelay(
        DisconnectReason.disconnected,
        now: now.add(const Duration(seconds: 58)),
      ),
      isNull,
    );
  });

  test('稳定连接达到 30 秒后重置恢复预算', () {
    final policy = CallRecoveryPolicy();
    policy.nextDelay(DisconnectReason.disconnected, now: now);
    policy.nextDelay(DisconnectReason.disconnected, now: now);
    policy.markConnected(now);
    final disconnectedAt = now.add(const Duration(seconds: 30));
    expect(
      policy.nextDelay(DisconnectReason.disconnected, now: disconnectedAt),
      const Duration(seconds: 2),
    );
    expect(
      policy.nextDelay(DisconnectReason.disconnected, now: disconnectedAt),
      const Duration(seconds: 5),
    );
  });

  test('主动开始新通话可显式重置恢复预算', () {
    final policy = CallRecoveryPolicy();
    policy.nextDelay(DisconnectReason.disconnected, now: now);
    policy.nextDelay(DisconnectReason.disconnected, now: now);
    policy.reset();
    expect(
      policy.nextDelay(DisconnectReason.disconnected, now: now),
      const Duration(seconds: 2),
    );
  });
}

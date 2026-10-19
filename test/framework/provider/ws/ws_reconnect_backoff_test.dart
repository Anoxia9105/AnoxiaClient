// WebSocket 重连退避（Full Jitter）单元测试。
//
// 锁定 calculateReconnectDelaySeconds 的语义：
// - 基准间隔 clamp(2^attempt, 2, 30)；
// - 实际间隔均匀落在 [1, baseDelay] 区间（Full Jitter），
//   这是 AGENTS.md 里防止后端重启惊群的关键行为；
// - attempt 超大时饱和在 30s，不允许 1<<n 整数回绕产生小间隔。
import 'dart:math' as math;

import 'package:anoxia/framework/provider/ws/ws_reconnect_backoff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateReconnectDelaySeconds', () {
    int baseDelayFor(int attempt) =>
        (1 << attempt.clamp(0, 5)).clamp(2, 30);

    test('attempt=0 的基准间隔为 2s，延迟落在 [1, 2]', () {
      for (var i = 0; i < 200; i++) {
        final d = calculateReconnectDelaySeconds(0, random: math.Random(i));
        expect(d, greaterThanOrEqualTo(1));
        expect(d, lessThanOrEqualTo(2));
      }
    });

    test('attempt=1 的基准间隔为 4s，延迟不越过 [1, 4]', () {
      for (var i = 0; i < 200; i++) {
        final d = calculateReconnectDelaySeconds(1, random: math.Random(i));
        expect(d, greaterThanOrEqualTo(1));
        expect(d, lessThanOrEqualTo(baseDelayFor(1)));
      }
    });

    test('attempt 超过封顶点后始终 ≤ 30s（不会回绕成小间隔）', () {
      // 最大的 jitter 上限与 attempt 无关地封在 30。
      for (final attempt in [5, 6, 10, 61, 62, 100, 10000]) {
        for (var i = 0; i < 50; i++) {
          final d = calculateReconnectDelaySeconds(
            attempt,
            random: math.Random(i),
          );
          expect(d, lessThanOrEqualTo(maxReconnectDelaySeconds));
          expect(d, greaterThanOrEqualTo(1));
        }
      }
    });

    test('同一 attempt 的多次延迟呈现随机分布而非固定值（Full Jitter 特征）', () {
      final values = {
        for (var i = 0; i < 300; i++) calculateReconnectDelaySeconds(5, random: math.Random(i)),
      };
      // [1, 30] 均匀分布 300 次采样应命中的不同取值远大于 1。
      expect(values.length, greaterThan(10));
    });

    test('无法复现具体秒数，但可复现区间分布（有 jitter 而非固定退避）', () {
      // 与固定退避（attempt 决定唯一值）不同：同一 attempt 不总返回同一值。
      final first = calculateReconnectDelaySeconds(3, random: math.Random(0));
      final differs = List.generate(
        100,
        (i) => calculateReconnectDelaySeconds(3, random: math.Random(i)) != first,
      );
      expect(differs.where((v) => v).length, greaterThan(0));
    });
  });
}

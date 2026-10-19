// WebSocket 重连退避间隔计算（Full Jitter）。
//
// 独立成纯函数以便单测锁定语义：AGENTS.md 明确要求固定 2s/4s/8s 的
// 死板退避会造成后端重启时的重连惊群，这里必须带 Full Jitter。
import 'dart:math' as math;

/// 重连退避尝试次数上限的对数移位封顶值。
///
/// `1 << 5 = 32`，clamp 到 MAX 之后任何更晚的尝试都在 [1, MAX] 内；
/// 同时避免超大 attempt 时 `1 << n` 的整数回绕（历史上第 62 次起
/// 会回绕成负数、clamp 出 2s 小间隔，与「越久越慢、封顶 30s」的意图矛盾）。
const int _maxShift = 5;

/// 单次重连的最大间隔（秒）。
const int maxReconnectDelaySeconds = 30;

/// 计算下一次重连延迟（秒）。
///
/// - 基准间隔：`clamp(2^attempt, 2, 30)` 秒（1s、2s 之余封顶 30s）；
/// - 实际间隔：在 `[1, baseDelay]` 上均匀随机取整秒（Full Jitter），
///   把后端重启后的同一批客户端分散开，降低 Redis/MySQL 鉴权瞬时压力。
int calculateReconnectDelaySeconds(int attempt, {math.Random? random}) {
  final baseDelay = (1 << attempt.clamp(0, _maxShift)).clamp(2, maxReconnectDelaySeconds);
  final rng = random ?? math.Random();
  final jitterMs = rng.nextInt(baseDelay * 1000);
  return math.max(1, (jitterMs / 1000).round());
}

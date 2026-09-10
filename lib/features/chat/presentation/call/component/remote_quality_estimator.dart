import 'package:livekit_client/livekit_client.dart';

/// 远端下行质量估算器
///
/// 服务端转发的上行质量（`ParticipantConnectionQualityUpdatedEvent`）优先。
/// 仅当服务端质量长期为 `unknown`（Web 下 SFU 下发少/晚）时，用本地已订阅
/// 远端轨的 `getReceiverStats()` 做下行视角兜底，避免信号条一直灰色未知。
/// 估算结果调用方必须以“估算”弱提示展示，不与服务端值混淆。
class RemoteQualityEstimator {
  /// 丢包率阈值：>= 此值判为 poor
  static const double poorLossRate = 0.08;

  /// 丢包率阈值：>= 此值判为 lost
  static const double lostLossRate = 0.25;

  /// jitter 阈值（秒）：>= 此值判为 poor
  static const double poorJitterSec = 0.08;

  /// jitter 阈值（秒）：>= 此值判为 lost
  static const double lostJitterSec = 0.2;

  /// 视频掉帧率阈值：>= 此值判为 poor / lost
  static const double poorDropRate = 0.1;
  static const double lostDropRate = 0.3;

  /// 纯函数映射，便于单测。
  ///
  /// [hasActiveTrack] 无已订阅轨时返回 null（无法估算，保持 unknown）。
  static ConnectionQuality? mapDownlinkToQuality({
    required bool hasActiveTrack,
    double? audioLossRate,
    double? audioJitterSec,
    double? videoLossRate,
    double? videoDropRate,
  }) {
    if (!hasActiveTrack) return null;
    final double worstLoss = <double?>[
      audioLossRate,
      videoLossRate,
    ].whereType<double>().fold<double>(0, (a, b) => a > b ? a : b);
    final double jitter = audioJitterSec ?? 0;
    final double dropRate = videoDropRate ?? 0;

    if (worstLoss >= lostLossRate ||
        jitter >= lostJitterSec ||
        dropRate >= lostDropRate) {
      return ConnectionQuality.lost;
    }
    if (worstLoss >= poorLossRate ||
        jitter >= poorJitterSec ||
        dropRate >= poorDropRate) {
      return ConnectionQuality.poor;
    }
    return ConnectionQuality.good;
  }

  /// 对远端参与者做一次下行估算。
  ///
  /// 无已订阅远端轨 / 取数失败 / 无有效数据时返回 null（保持 unknown，
  /// 不伪造信号）。正常下行返回 `good`，弱网返回 `poor`/`lost`。
  static Future<ConnectionQuality?> estimateRemoteDownlinkQuality(
    RemoteParticipant participant,
  ) async {
    bool hasActiveTrack = false;
    double? audioLossRate;
    double? audioJitterSec;
    double? videoLossRate;
    double? videoDropRate;

    for (final pub in participant.audioTrackPublications) {
      if (!pub.subscribed) continue;
      final track = pub.track;
      if (track is! RemoteAudioTrack) continue;
      hasActiveTrack = true;
      try {
        final stats = await track
            .getReceiverStats()
            .timeout(const Duration(seconds: 2));
        if (stats == null) continue;
        final num lost = stats.packetsLost ?? 0;
        final num received = stats.packetsReceived ?? 0;
        final num total = lost + received;
        if (total > 0) {
          audioLossRate = (lost / total).toDouble().clamp(0.0, 1.0);
        }
        final num jitter = stats.jitter ?? 0;
        if (jitter > 0) audioJitterSec = jitter.toDouble();
      } catch (_) {
        continue;
      }
    }

    for (final pub in participant.videoTrackPublications) {
      if (!pub.subscribed) continue;
      final track = pub.track;
      if (track is! RemoteVideoTrack) continue;
      hasActiveTrack = true;
      try {
        final stats = await track
            .getReceiverStats()
            .timeout(const Duration(seconds: 2));
        if (stats == null) continue;
        final num lost = stats.packetsLost ?? 0;
        final num received = stats.packetsReceived ?? 0;
        final num total = lost + received;
        if (total > 0) {
          final double rate = (lost / total).toDouble().clamp(0.0, 1.0);
          videoLossRate =
              videoLossRate == null || rate > videoLossRate ? rate : videoLossRate;
        }
        final num dropped = stats.framesDropped ?? 0;
        final num decoded = stats.framesDecoded ?? 0;
        final num framesTotal = dropped + decoded;
        if (framesTotal > 0) {
          videoDropRate = (dropped / framesTotal).toDouble().clamp(0.0, 1.0);
        }
      } catch (_) {
        continue;
      }
    }

    if (!hasActiveTrack) return null;
    // 有轨但一包数据都拿不到：不断言信号，保持 unknown。
    if (audioLossRate == null &&
        audioJitterSec == null &&
        videoLossRate == null &&
        videoDropRate == null) {
      return null;
    }
    return mapDownlinkToQuality(
      hasActiveTrack: true,
      audioLossRate: audioLossRate,
      audioJitterSec: audioJitterSec,
      videoLossRate: videoLossRate,
      videoDropRate: videoDropRate,
    );
  }
}

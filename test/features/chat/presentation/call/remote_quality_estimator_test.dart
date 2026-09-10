import 'package:anoxia/features/chat/presentation/call/component/remote_quality_estimator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart';

void main() {
  group('RemoteQualityEstimator.mapDownlinkToQuality', () {
    test('无订阅轨时返回 null（保持未知，不伪造）', () {
      expect(
        RemoteQualityEstimator.mapDownlinkToQuality(hasActiveTrack: false),
        isNull,
      );
    });

    test('丢包抖动正常时估算为 good', () {
      expect(
        RemoteQualityEstimator.mapDownlinkToQuality(
          hasActiveTrack: true,
          audioLossRate: 0.01,
          audioJitterSec: 0.02,
          videoLossRate: 0.01,
          videoDropRate: 0.02,
        ),
        ConnectionQuality.good,
      );
    });

    test('轻度丢包或抖动时估算为 poor', () {
      expect(
        RemoteQualityEstimator.mapDownlinkToQuality(
          hasActiveTrack: true,
          audioLossRate: 0.1,
        ),
        ConnectionQuality.poor,
      );
      expect(
        RemoteQualityEstimator.mapDownlinkToQuality(
          hasActiveTrack: true,
          audioJitterSec: 0.1,
        ),
        ConnectionQuality.poor,
      );
      expect(
        RemoteQualityEstimator.mapDownlinkToQuality(
          hasActiveTrack: true,
          videoDropRate: 0.15,
        ),
        ConnectionQuality.poor,
      );
    });

    test('严重丢包或抖动时估算为 lost', () {
      expect(
        RemoteQualityEstimator.mapDownlinkToQuality(
          hasActiveTrack: true,
          audioLossRate: 0.3,
        ),
        ConnectionQuality.lost,
      );
      expect(
        RemoteQualityEstimator.mapDownlinkToQuality(
          hasActiveTrack: true,
          videoDropRate: 0.4,
        ),
        ConnectionQuality.lost,
      );
    });
  });
}

/// SDK 没有提供瞬时 FPS 时，按相邻累计帧数与统计时间戳计算区间 FPS。
class RtpFrameRateWindow {
  RtpFrameRateWindow({required this.ticksPerSecond});

  final num ticksPerSecond;
  final _samples = <String, (num, num)>{};
  final _rates = <String, double>{};

  double? observe(String key, num timestamp, num? frames, num? sdkFps) {
    double? rate;
    if (frames == null || !frames.isFinite || !timestamp.isFinite) {
      _samples.remove(key);
      _rates.remove(key);
    } else {
      final previous = _samples[key];
      if (previous != null && timestamp == previous.$1) {
        rate = _rates[key];
      } else {
        _samples[key] = (timestamp, frames);
        if (previous != null &&
            timestamp > previous.$1 &&
            frames >= previous.$2) {
          rate =
              (frames - previous.$2) *
              ticksPerSecond /
              (timestamp - previous.$1);
          _rates[key] = rate;
        } else {
          _rates.remove(key);
        }
      }
    }
    // 零 FPS 是有效统计；不能用目标帧率或旧值掩盖停止出帧。
    return sdkFps != null && sdkFps.isFinite && sdkFps >= 0
        ? sdkFps.toDouble()
        : rate;
  }

  void retainOnly(Set<String> keys) {
    _samples.removeWhere((key, _) => !keys.contains(key));
    _rates.removeWhere((key, _) => !keys.contains(key));
  }
}

import 'dart:math' as math;

/// WebRTC 的累计计数；timestamp 仅用于排序，不依赖平台的时间单位。
class RtpCounters {
  const RtpCounters({
    required this.timestamp,
    this.lost,
    this.received,
    this.dropped,
    this.decoded,
  });
  final num timestamp;
  final num? lost;
  final num? received;
  final num? dropped;
  final num? decoded;
}

class RtpInterval {
  const RtpInterval({this.lossRate, this.dropRate});
  final double? lossRate;
  final double? dropRate;
}

/// 每条流维护一个基线；重复读取同一 SDK 缓存样本不会伪造零丢包。
class RtpSampleWindow {
  final Map<String, RtpCounters> _previous = {};
  final Map<String, RtpInterval> _intervals = {};

  RtpInterval? observe(String key, RtpCounters current) {
    final previous = _previous[key];
    if (previous != null && current.timestamp == previous.timestamp) {
      return _intervals[key];
    }
    _previous[key] = current;
    if (previous == null ||
        current.timestamp < previous.timestamp ||
        _reset(current.received, previous.received) ||
        _reset(current.decoded, previous.decoded) ||
        _reset(current.dropped, previous.dropped)) {
      _intervals.remove(key);
      return null;
    }
    final interval = RtpInterval(
      lossRate: _rate(
        current.lost,
        previous.lost,
        current.received,
        previous.received,
      ),
      dropRate: _rate(
        current.dropped,
        previous.dropped,
        current.decoded,
        previous.decoded,
      ),
    );
    _intervals[key] = interval;
    return interval;
  }

  static bool _reset(num? current, num? previous) =>
      current != null && previous != null && current < previous;

  static double? _rate(
    num? bad,
    num? previousBad,
    num? good,
    num? previousGood,
  ) {
    if (bad == null ||
        previousBad == null ||
        good == null ||
        previousGood == null) {
      return null;
    }
    final badDelta = math.max(0, bad - previousBad);
    final goodDelta = math.max(0, good - previousGood);
    final total = badDelta + goodDelta;
    return total > 0 ? (badDelta / total).toDouble().clamp(0, 1) : null;
  }

  void retainOnly(Set<String> keys) {
    _previous.removeWhere((key, _) => !keys.contains(key));
    _intervals.removeWhere((key, _) => !keys.contains(key));
  }
}

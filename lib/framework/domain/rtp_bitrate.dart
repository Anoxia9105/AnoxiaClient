/// 字节累计计数换算为 bit/s。Web 时间戳为毫秒，原生为微秒。
class RtpBitrateWindow {
  RtpBitrateWindow({required this.ticksPerSecond});
  final num ticksPerSecond;
  final _samples = <String, (num, num)>{};
  final _rates = <String, double>{};

  double? observe(String key, num timestamp, num? bytes) {
    if (bytes == null || !bytes.isFinite || !timestamp.isFinite) {
      _samples.remove(key);
      _rates.remove(key);
      return null;
    }
    final previous = _samples[key];
    if (previous != null && timestamp == previous.$1) return _rates[key];
    _samples[key] = (timestamp, bytes);
    if (previous == null || timestamp < previous.$1 || bytes < previous.$2) {
      _rates.remove(key);
      return null;
    }
    return _rates[key] =
        (bytes - previous.$2) * 8 * ticksPerSecond / (timestamp - previous.$1);
  }

  void retainOnly(Set<String> keys) {
    _samples.removeWhere((key, _) => !keys.contains(key));
    _rates.removeWhere((key, _) => !keys.contains(key));
  }
}

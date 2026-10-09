import 'package:anoxia/framework/domain/rtp_bitrate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final ticks in [1000, 1000000]) {
    test('时间单位 $ticks：一秒发送125KB应显示1Mbps', () {
      final window = RtpBitrateWindow(ticksPerSecond: ticks);
      expect(window.observe('video', ticks, 500), isNull);
      expect(window.observe('video', ticks * 2, 125500), 1000000);
      expect(window.observe('video', ticks * 2, 125500), 1000000);
      expect(window.observe('video', ticks * 3, 125500), 0);
      expect(window.observe('video', ticks * 4, 10), isNull);
      expect(window.observe('video', ticks * 5, null), isNull);
      expect(window.observe('video', ticks * 6, 100), isNull);
    });
  }
}

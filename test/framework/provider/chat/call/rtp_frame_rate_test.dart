import 'package:anoxia/framework/domain/rtp_frame_rate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('缺失 FPS 时按原生微秒计数差计算，重复样本不产生零值', () {
    final window = RtpFrameRateWindow(ticksPerSecond: 1000000);
    expect(window.observe('share', 1000000, 20, null), isNull);
    expect(window.observe('share', 4000000, 110, null), 30);
    expect(window.observe('share', 4000000, 110, null), 30);
    expect(window.observe('share', 7000000, 110, null), 0);
  });

  test('优先保留 SDK 的低 FPS 和零 FPS，不拿上限伪装实际帧率', () {
    final window = RtpFrameRateWindow(ticksPerSecond: 1000);
    expect(window.observe('share', 1000, 20, 2), 2);
    expect(window.observe('share', 4000, 110, 0), 0);
    expect(window.observe('share', 7000, 200, null), 30);
  });

  test('流计数重置、切换和撤销共享不会沿用旧基线', () {
    final window = RtpFrameRateWindow(ticksPerSecond: 1000);
    window.observe('share', 1000, 100, null);
    expect(window.observe('share', 4000, 5, null), isNull);
    expect(window.observe('share', 7000, 50, null), 15);
    expect(window.observe('other', 7000, 50, null), isNull);
    window.retainOnly({});
    expect(window.observe('share', 10000, 100, null), isNull);
  });
}

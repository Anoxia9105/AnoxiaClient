import 'package:anoxia/framework/domain/rtp_interval.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('质量使用最近区间，弱网恢复不被历史累计丢包拖住', () {
    final window = RtpSampleWindow();
    expect(
      window.observe(
        'a',
        const RtpCounters(timestamp: 1, lost: 0, received: 0),
      ),
      isNull,
    );
    expect(
      window
          .observe(
            'a',
            const RtpCounters(timestamp: 2, lost: 30, received: 70),
          )!
          .lossRate,
      0.3,
    );
    expect(
      window
          .observe(
            'a',
            const RtpCounters(timestamp: 3, lost: 30, received: 170),
          )!
          .lossRate,
      0,
    );
  });
  test('重复样本不产生假恢复，重连计数重置后重新建立基线', () {
    final window = RtpSampleWindow();
    window.observe('a', const RtpCounters(timestamp: 1, lost: 0, received: 0));
    final weak = window.observe(
      'a',
      const RtpCounters(timestamp: 2, lost: 30, received: 70),
    );
    expect(
      window.observe(
        'a',
        const RtpCounters(timestamp: 2, lost: 30, received: 70),
      ),
      same(weak),
    );
    expect(
      window.observe(
        'a',
        const RtpCounters(timestamp: 3, lost: 0, received: 1),
      ),
      isNull,
    );
    expect(
      window
          .observe(
            'a',
            const RtpCounters(timestamp: 4, lost: 0, received: 101),
          )!
          .lossRate,
      0,
    );
  });
  test('迟到包导致负丢包增量时不会得到负丢包率', () {
    final window = RtpSampleWindow();
    window.observe(
      'a',
      const RtpCounters(timestamp: 1, lost: 4, received: 100),
    );
    expect(
      window
          .observe(
            'a',
            const RtpCounters(timestamp: 2, lost: 2, received: 200),
          )!
          .lossRate,
      0,
    );
  });
  test('掉帧只衡量本次区间，已移除轨道不会保留旧基线', () {
    final window = RtpSampleWindow();
    window.observe(
      'v',
      const RtpCounters(timestamp: 1, dropped: 10, decoded: 90),
    );
    expect(
      window
          .observe(
            'v',
            const RtpCounters(timestamp: 2, dropped: 10, decoded: 190),
          )!
          .dropRate,
      0,
    );
    window.retainOnly({});
    expect(
      window.observe(
        'v',
        const RtpCounters(timestamp: 3, dropped: 10, decoded: 290),
      ),
      isNull,
    );
  });
}

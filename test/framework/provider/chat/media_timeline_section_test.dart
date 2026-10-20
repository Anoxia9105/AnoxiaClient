import 'package:anoxia/framework/provider/chat/media/media_timeline_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('链接过滤为空时保留源分页游标', () {
    const section = MediaTimelineSection(
      items: [], hasMore: true, sourceCursor: 42,
    );
    expect(section.isEmpty, isTrue);
    expect(section.oldestSeq, 42);
    expect(section.hasMore, isTrue);
  });
}

import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses server UTC instants and serializes writes as UTC', () {
    final event = ScheduleEvent.fromJson({
      'id': 9,
      'title': '产品评审',
      'description': '确认 MVP 范围',
      'location': '线上',
      'startAt': '2026-09-22T01:00:00Z',
      'endAt': '2026-09-22T02:00:00Z',
      'timeZone': 'Asia/Shanghai',
      'allDay': false,
      'color': '#4F6BED',
      'revision': 3,
    });

    expect(event.startAt.isUtc, isTrue);
    expect(event.revision, 3);
    expect(event.toWriteJson()['startAt'], '2026-09-22T01:00:00.000Z');
  });

  test('week range starts on Monday and ends exclusively next Monday', () {
    final range = scheduleRangeFor(
      ScheduleViewMode.week,
      DateTime(2026, 9, 24),
    );

    expect(range.from, DateTime(2026, 9, 21));
    expect(range.to, DateTime(2026, 9, 28));
  });

  test('month range includes adjacent calendar cells', () {
    final range = scheduleRangeFor(
      ScheduleViewMode.month,
      DateTime(2026, 9, 24),
    );

    expect(range.from, DateTime(2026, 8, 25));
    expect(range.to, DateTime(2026, 10, 8));
  });

  test('all-day events preserve their calendar date across time zones', () {
    final event = ScheduleEvent.fromJson({
      'id': 10,
      'title': '全天日程',
      'startAt': '2026-09-22T00:00:00Z',
      'endAt': '2026-09-23T00:00:00Z',
      'timeZone': 'UTC',
      'allDay': true,
      'revision': 1,
    });

    expect(event.displayStartAt, DateTime(2026, 9, 22));
    expect(event.displayEndAt, DateTime(2026, 9, 23));
  });

  test('view range excludes events loaded only for the quick panel', () {
    final visible = ScheduleEvent(
      id: 1,
      title: 'visible',
      startAt: DateTime.utc(2026, 10, 2, 1),
      endAt: DateTime.utc(2026, 10, 2, 2),
      timeZone: 'UTC',
      allDay: false,
      revision: 1,
    );
    final quickPanelOnly = ScheduleEvent(
      id: 2,
      title: 'quick panel only',
      startAt: DateTime.utc(2026, 9, 22, 1),
      endAt: DateTime.utc(2026, 9, 22, 2),
      timeZone: 'UTC',
      allDay: false,
      revision: 1,
    );

    final result = scheduleEventsOverlapping([
      quickPanelOnly,
      visible,
    ], ScheduleRange(from: DateTime.utc(2026, 10), to: DateTime.utc(2026, 11)));

    expect(result.map((event) => event.id), [1]);
  });
}

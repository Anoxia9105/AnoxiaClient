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

  test('parses and serializes reminder and recurrence fields', () {
    final event = ScheduleEvent.fromJson({
      'id': 11,
      'title': '每周同步',
      'startAt': '2026-09-21T01:00:00Z',
      'endAt': '2026-09-21T02:00:00Z',
      'timeZone': 'Asia/Shanghai',
      'allDay': false,
      'revision': 2,
      'reminderMinutes': 15,
      'recurrence': {
        'frequency': 'WEEKLY',
        'interval': 1,
        'weekdays': [1, 3, 5],
        'endType': 'UNTIL',
        'until': '2026-10-31T23:59:59Z',
      },
    });

    expect(event.reminderMinutes, 15);
    expect(event.recurrence?.frequency, ScheduleRecurrenceFrequency.weekly);
    expect(event.recurrence?.weekdays, [1, 3, 5]);
    expect(
      event.toWriteJson()['recurrence'],
      containsPair('frequency', 'WEEKLY'),
    );
  });

  test('expands daily recurrence only inside the requested range', () {
    final event = _recurringEvent(
      recurrence: const ScheduleRecurrence(
        frequency: ScheduleRecurrenceFrequency.daily,
        interval: 2,
      ),
    );

    final occurrences = expandScheduleOccurrences(
      [event],
      ScheduleRange(
        from: DateTime.utc(2026, 9, 22),
        to: DateTime.utc(2026, 9, 28),
      ),
    );

    expect(occurrences.map((item) => item.startAt.day), [23, 25, 27]);
  });

  test('expands selected weekdays and respects occurrence count', () {
    final event = _recurringEvent(
      startAt: DateTime.utc(2026, 9, 21, 1),
      recurrence: const ScheduleRecurrence(
        frequency: ScheduleRecurrenceFrequency.weekly,
        weekdays: [DateTime.monday, DateTime.wednesday],
        endType: ScheduleRecurrenceEndType.count,
        count: 3,
      ),
    );

    final occurrences = expandScheduleOccurrences(
      [event],
      ScheduleRange(
        from: DateTime.utc(2026, 9, 20),
        to: DateTime.utc(2026, 10, 20),
      ),
    );

    expect(occurrences.map((item) => item.startAt.toIso8601String()), [
      '2026-09-21T01:00:00.000Z',
      '2026-09-23T01:00:00.000Z',
      '2026-09-28T01:00:00.000Z',
    ]);
  });

  test('monthly recurrence clamps to the last day of short months', () {
    final event = _recurringEvent(
      startAt: DateTime.utc(2027, 1, 31, 1),
      recurrence: const ScheduleRecurrence(
        frequency: ScheduleRecurrenceFrequency.monthly,
        endType: ScheduleRecurrenceEndType.count,
        count: 3,
      ),
    );

    final occurrences = expandScheduleOccurrences([
      event,
    ], ScheduleRange(from: DateTime.utc(2027, 1), to: DateTime.utc(2027, 4)));

    expect(
      occurrences.map((item) => '${item.startAt.month}-${item.startAt.day}'),
      ['1-31', '2-28', '3-31'],
    );
  });
}

ScheduleEvent _recurringEvent({
  DateTime? startAt,
  required ScheduleRecurrence recurrence,
}) {
  final start = startAt ?? DateTime.utc(2026, 9, 21, 1);
  return ScheduleEvent(
    id: 99,
    title: '重复日程',
    startAt: start,
    endAt: start.add(const Duration(hours: 1)),
    timeZone: 'UTC',
    allDay: false,
    revision: 1,
    recurrence: recurrence,
  );
}

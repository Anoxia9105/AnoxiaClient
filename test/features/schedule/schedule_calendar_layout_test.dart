import 'package:anoxia/features/schedule/presentation/schedule_calendar_layout.dart';
import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(initializeDateFormatting);

  test('month grid always starts on Monday and contains 42 days', () {
    final days = scheduleMonthGridDays(DateTime(2026, 9, 15));

    expect(days, hasLength(42));
    expect(days.first, DateTime(2026, 8, 31));
    expect(days.first.weekday, DateTime.monday);
    expect(days.last, DateTime(2026, 10, 11));
  });

  test('week timeline starts on Monday', () {
    final days = scheduleTimelineDays(DateTime(2026, 9, 24), week: true);

    expect(days.first, DateTime(2026, 9, 21));
    expect(days.last, DateTime(2026, 9, 27));
  });

  test('timeline movement snaps to 15 minute boundaries', () {
    expect(snapScheduleMinutes(7), 0);
    expect(snapScheduleMinutes(8), 15);
    expect(snapScheduleMinutes(52), 45);
    expect(snapScheduleMinutes(53), 60);
  });

  test('reminder trigger is derived from each occurrence start', () {
    final event = ScheduleEvent(
      id: 1,
      title: 'review',
      startAt: DateTime.utc(2026, 9, 22, 8),
      endAt: DateTime.utc(2026, 9, 22, 9),
      timeZone: 'UTC',
      allDay: false,
      revision: 1,
      reminderMinutes: 30,
    );
    final occurrence = ScheduleOccurrence(
      event: event,
      startAt: DateTime.utc(2026, 9, 24, 8),
      endAt: DateTime.utc(2026, 9, 24, 9),
      occurrenceIndex: 2,
    );

    expect(
      scheduleReminderTriggerAt(occurrence)?.toUtc(),
      DateTime.utc(2026, 9, 24, 7, 30),
    );
  });

  test('overlapping occurrences are assigned side-by-side columns', () {
    ScheduleOccurrence occurrence(int id, int startHour, int endHour) {
      final event = ScheduleEvent(
        id: id,
        title: 'event $id',
        startAt: DateTime.utc(2026, 9, 22, startHour),
        endAt: DateTime.utc(2026, 9, 22, endHour),
        timeZone: 'UTC',
        allDay: false,
        revision: 1,
      );
      return ScheduleOccurrence(
        event: event,
        startAt: event.startAt,
        endAt: event.endAt,
        occurrenceIndex: 0,
      );
    }

    final layouts = layoutScheduleOccurrences([
      occurrence(1, 9, 11),
      occurrence(2, 10, 12),
      occurrence(3, 12, 13),
    ]);

    expect(layouts.map((item) => item.columnCount), [2, 2, 1]);
    expect(layouts.map((item) => item.column), [0, 1, 0]);
  });

  test('weekday and month labels follow zh, en and ja locales', () {
    final monday = DateTime(2026, 9, 21);

    expect(DateFormat.E('zh').format(monday), isNot('Mon'));
    expect(DateFormat.E('en').format(monday), 'Mon');
    expect(DateFormat.E('ja').format(monday), isNot('Mon'));
    expect(DateFormat.yMMMM('en').format(monday), 'September 2026');
    expect(DateFormat.yMMMM('zh').format(monday), contains('9'));
    expect(DateFormat.yMMMM('ja').format(monday), contains('9'));
  });
}

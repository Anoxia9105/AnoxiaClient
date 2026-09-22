import 'package:anoxia/framework/domain/schedule_event.dart';

const scheduleMinutesPerStep = 15;

class ScheduleOccurrenceLayout {
  final ScheduleOccurrence occurrence;
  final int column;
  final int columnCount;

  const ScheduleOccurrenceLayout({
    required this.occurrence,
    required this.column,
    required this.columnCount,
  });
}

List<DateTime> scheduleMonthGridDays(DateTime focusedDay) {
  final first = DateTime(focusedDay.year, focusedDay.month);
  final gridStart = first.subtract(
    Duration(days: first.weekday - DateTime.monday),
  );
  return List.generate(42, (index) => gridStart.add(Duration(days: index)));
}

List<DateTime> scheduleTimelineDays(DateTime focusedDay, {required bool week}) {
  final day = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
  if (!week) return [day];
  final monday = day.subtract(Duration(days: day.weekday - DateTime.monday));
  return List.generate(7, (index) => monday.add(Duration(days: index)));
}

int snapScheduleMinutes(double minutes) {
  return (minutes / scheduleMinutesPerStep).round() * scheduleMinutesPerStep;
}

List<ScheduleOccurrenceLayout> layoutScheduleOccurrences(
  Iterable<ScheduleOccurrence> occurrences,
) {
  final sorted = [...occurrences]
    ..sort((a, b) => a.startAt.compareTo(b.startAt));
  final result = <ScheduleOccurrenceLayout>[];
  var cursor = 0;
  while (cursor < sorted.length) {
    final cluster = <ScheduleOccurrence>[];
    var clusterEnd = sorted[cursor].endAt;
    do {
      final occurrence = sorted[cursor++];
      cluster.add(occurrence);
      if (occurrence.endAt.isAfter(clusterEnd)) clusterEnd = occurrence.endAt;
    } while (cursor < sorted.length &&
        sorted[cursor].startAt.isBefore(clusterEnd));

    final columnEnds = <DateTime>[];
    final assignments = <({ScheduleOccurrence occurrence, int column})>[];
    for (final occurrence in cluster) {
      var column = columnEnds.indexWhere(
        (end) => !end.isAfter(occurrence.startAt),
      );
      if (column < 0) {
        column = columnEnds.length;
        columnEnds.add(occurrence.endAt);
      } else {
        columnEnds[column] = occurrence.endAt;
      }
      assignments.add((occurrence: occurrence, column: column));
    }
    for (final assignment in assignments) {
      result.add(
        ScheduleOccurrenceLayout(
          occurrence: assignment.occurrence,
          column: assignment.column,
          columnCount: columnEnds.length,
        ),
      );
    }
  }
  return result;
}

bool scheduleOccurrenceIsOnDay(ScheduleOccurrence occurrence, DateTime day) {
  final start = scheduleOccurrenceDisplayStart(occurrence);
  final end = scheduleOccurrenceDisplayEnd(occurrence);
  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  return end.isAfter(dayStart) && start.isBefore(dayEnd);
}

DateTime scheduleOccurrenceDisplayStart(ScheduleOccurrence occurrence) {
  if (!occurrence.event.allDay) return occurrence.startAt.toLocal();
  final value = occurrence.startAt.toUtc();
  return DateTime(value.year, value.month, value.day);
}

DateTime scheduleOccurrenceDisplayEnd(ScheduleOccurrence occurrence) {
  if (!occurrence.event.allDay) return occurrence.endAt.toLocal();
  final value = occurrence.endAt.toUtc();
  return DateTime(value.year, value.month, value.day);
}

DateTime? scheduleReminderTriggerAt(ScheduleOccurrence occurrence) {
  final minutes = occurrence.event.reminderMinutes;
  if (minutes == null) return null;
  return occurrence.startAt.toLocal().subtract(Duration(minutes: minutes));
}

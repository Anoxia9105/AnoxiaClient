/// 日程日历展示模式。
enum ScheduleViewMode { day, week, month, agenda }

enum ScheduleRecurrenceFrequency { daily, weekly, monthly }

enum ScheduleRecurrenceEndType { never, until, count }

class ScheduleRecurrence {
  final ScheduleRecurrenceFrequency frequency;
  final int interval;
  final List<int> weekdays;
  final ScheduleRecurrenceEndType endType;
  final DateTime? until;
  final int? count;

  const ScheduleRecurrence({
    required this.frequency,
    this.interval = 1,
    this.weekdays = const [],
    this.endType = ScheduleRecurrenceEndType.never,
    this.until,
    this.count,
  });

  factory ScheduleRecurrence.fromJson(Map<String, dynamic> json) {
    return ScheduleRecurrence(
      frequency: _enumByWireValue(
        ScheduleRecurrenceFrequency.values,
        json['frequency'],
        ScheduleRecurrenceFrequency.daily,
      ),
      interval: int.tryParse(json['interval']?.toString() ?? '') ?? 1,
      weekdays: (json['weekdays'] as List? ?? const [])
          .map((value) => int.tryParse(value.toString()))
          .whereType<int>()
          .toList(growable: false),
      endType: _enumByWireValue(
        ScheduleRecurrenceEndType.values,
        json['endType'],
        ScheduleRecurrenceEndType.never,
      ),
      until: _optionalDateTime(json['until']),
      count: int.tryParse(json['count']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.name.toUpperCase(),
      'interval': interval,
      'weekdays': weekdays,
      'endType': endType.name.toUpperCase(),
      'until': until?.toUtc().toIso8601String(),
      'count': count,
    };
  }
}

/// 服务端查询使用的左闭右开时间窗口。
class ScheduleRange {
  final DateTime from;
  final DateTime to;

  const ScheduleRange({required this.from, required this.to});
}

ScheduleRange scheduleRangeFor(ScheduleViewMode mode, DateTime focusedDay) {
  final day = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
  switch (mode) {
    case ScheduleViewMode.day:
      return ScheduleRange(from: day, to: day.add(const Duration(days: 1)));
    case ScheduleViewMode.week:
      final monday = day.subtract(
        Duration(days: day.weekday - DateTime.monday),
      );
      return ScheduleRange(
        from: monday,
        to: monday.add(const Duration(days: 7)),
      );
    case ScheduleViewMode.month:
      final monthStart = DateTime(day.year, day.month);
      final nextMonth = DateTime(day.year, day.month + 1);
      return ScheduleRange(
        from: monthStart.subtract(const Duration(days: 7)),
        to: nextMonth.add(const Duration(days: 7)),
      );
    case ScheduleViewMode.agenda:
      return ScheduleRange(from: day, to: day.add(const Duration(days: 90)));
  }
}

List<ScheduleEvent> scheduleEventsOverlapping(
  Iterable<ScheduleEvent> events,
  ScheduleRange range,
) {
  final from = range.from.toUtc();
  final to = range.to.toUtc();
  return events
      .where((event) => event.endAt.isAfter(from) && event.startAt.isBefore(to))
      .toList(growable: false);
}

class ScheduleEvent {
  final int id;
  final String title;
  final String? description;
  final String? location;
  final DateTime startAt;
  final DateTime endAt;
  final String timeZone;
  final bool allDay;
  final String? color;
  final int revision;
  final int? reminderMinutes;
  final ScheduleRecurrence? recurrence;

  const ScheduleEvent({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.timeZone,
    required this.allDay,
    required this.revision,
    this.description,
    this.location,
    this.color,
    this.reminderMinutes,
    this.recurrence,
  });

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    return ScheduleEvent(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      description: _nullableString(json['description']),
      location: _nullableString(json['location']),
      startAt: DateTime.parse(json['startAt'].toString()).toUtc(),
      endAt: DateTime.parse(json['endAt'].toString()).toUtc(),
      timeZone: json['timeZone']?.toString() ?? 'UTC',
      allDay: json['allDay'] == true || json['allDay']?.toString() == '1',
      color: _nullableString(json['color']),
      revision: int.tryParse(json['revision']?.toString() ?? '') ?? 1,
      reminderMinutes: int.tryParse(json['reminderMinutes']?.toString() ?? ''),
      recurrence: json['recurrence'] is Map
          ? ScheduleRecurrence.fromJson(
              Map<String, dynamic>.from(json['recurrence'] as Map),
            )
          : null,
    );
  }

  /// 全天事件使用 UTC 年月日承载“日期”语义，避免跨时区后偏移一天。
  DateTime get displayStartAt => _displayDate(startAt);

  DateTime get displayEndAt => _displayDate(endAt);

  DateTime _displayDate(DateTime value) {
    if (!allDay) return value.toLocal();
    final utc = value.toUtc();
    return DateTime(utc.year, utc.month, utc.day);
  }

  Map<String, dynamic> toWriteJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'startAt': startAt.toUtc().toIso8601String(),
      'endAt': endAt.toUtc().toIso8601String(),
      'timeZone': timeZone,
      'allDay': allDay,
      'color': color,
      'reminderMinutes': reminderMinutes,
      'recurrence': recurrence?.toJson(),
      'revision': revision,
    };
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class ScheduleEventDraft {
  final String title;
  final String? description;
  final String? location;
  final DateTime startAt;
  final DateTime endAt;
  final bool allDay;
  final String timeZone;
  final String color;
  final int? revision;
  final int? reminderMinutes;
  final ScheduleRecurrence? recurrence;

  const ScheduleEventDraft({
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.allDay,
    this.description,
    this.location,
    this.timeZone = 'UTC',
    this.color = '#4F6BED',
    this.revision,
    this.reminderMinutes,
    this.recurrence,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title.trim(),
      'description': description?.trim(),
      'location': location?.trim(),
      'startAt': startAt.toUtc().toIso8601String(),
      'endAt': endAt.toUtc().toIso8601String(),
      'timeZone': timeZone,
      'allDay': allDay,
      'color': color,
      'reminderMinutes': reminderMinutes,
      'recurrence': recurrence?.toJson(),
      if (revision != null) 'revision': revision,
    };
  }
}

class ScheduleOccurrence {
  final ScheduleEvent event;
  final DateTime startAt;
  final DateTime endAt;
  final int occurrenceIndex;

  const ScheduleOccurrence({
    required this.event,
    required this.startAt,
    required this.endAt,
    required this.occurrenceIndex,
  });

  bool get isRecurring => event.recurrence != null;

  DateTime get displayStartAt => _displayDate(startAt, event.allDay);

  DateTime get displayEndAt => _displayDate(endAt, event.allDay);
}

List<ScheduleOccurrence> expandScheduleOccurrences(
  Iterable<ScheduleEvent> events,
  ScheduleRange range,
) {
  final from = range.from.toUtc();
  final to = range.to.toUtc();
  final occurrences = <ScheduleOccurrence>[];
  for (final event in events) {
    final recurrence = event.recurrence;
    if (recurrence == null) {
      if (_overlaps(event.startAt, event.endAt, from, to)) {
        occurrences.add(
          ScheduleOccurrence(
            event: event,
            startAt: event.startAt,
            endAt: event.endAt,
            occurrenceIndex: 0,
          ),
        );
      }
      continue;
    }
    occurrences.addAll(_expandRecurringEvent(event, recurrence, from, to));
  }
  occurrences.sort((a, b) {
    final byStart = a.startAt.compareTo(b.startAt);
    if (byStart != 0) return byStart;
    final byEnd = a.endAt.compareTo(b.endAt);
    if (byEnd != 0) return byEnd;
    return a.event.id.compareTo(b.event.id);
  });
  return occurrences;
}

Iterable<ScheduleOccurrence> _expandRecurringEvent(
  ScheduleEvent event,
  ScheduleRecurrence recurrence,
  DateTime from,
  DateTime to,
) sync* {
  final interval = recurrence.interval.clamp(1, 99);
  final duration = event.endAt.difference(event.startAt);
  const maxOccurrences = 100000;
  var occurrenceIndex = 0;

  bool canUse(DateTime start) {
    if (recurrence.endType == ScheduleRecurrenceEndType.count &&
        occurrenceIndex >= (recurrence.count ?? 0).clamp(1, 999)) {
      return false;
    }
    if (recurrence.endType == ScheduleRecurrenceEndType.until &&
        recurrence.until != null &&
        start.isAfter(recurrence.until!.toUtc())) {
      return false;
    }
    return true;
  }

  Iterable<DateTime> candidates() sync* {
    switch (recurrence.frequency) {
      case ScheduleRecurrenceFrequency.daily:
        for (var index = 0; index < maxOccurrences; index++) {
          yield _addUtcDays(event.startAt, index * interval);
        }
      case ScheduleRecurrenceFrequency.weekly:
        final weekdays = recurrence.weekdays
            .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
            .toSet();
        if (weekdays.isEmpty) weekdays.add(event.startAt.weekday);
        final anchorDay = DateTime.utc(
          event.startAt.year,
          event.startAt.month,
          event.startAt.day,
        );
        final anchorMonday = anchorDay.subtract(
          Duration(days: anchorDay.weekday - DateTime.monday),
        );
        for (var offset = 0; offset < maxOccurrences; offset++) {
          final day = anchorDay.add(Duration(days: offset));
          final weeks = day.difference(anchorMonday).inDays ~/ 7;
          if (weeks % interval != 0 || !weekdays.contains(day.weekday)) {
            continue;
          }
          final candidate = DateTime.utc(
            day.year,
            day.month,
            day.day,
            event.startAt.hour,
            event.startAt.minute,
            event.startAt.second,
            event.startAt.millisecond,
            event.startAt.microsecond,
          );
          if (!candidate.isBefore(event.startAt)) yield candidate;
        }
      case ScheduleRecurrenceFrequency.monthly:
        for (var index = 0; index < maxOccurrences; index++) {
          yield _addUtcMonthsClamped(event.startAt, index * interval);
        }
    }
  }

  for (final start in candidates()) {
    if (!canUse(start) || !start.isBefore(to)) break;
    final end = start.add(duration);
    if (_overlaps(start, end, from, to)) {
      yield ScheduleOccurrence(
        event: event,
        startAt: start,
        endAt: end,
        occurrenceIndex: occurrenceIndex,
      );
    }
    occurrenceIndex++;
  }
}

bool _overlaps(DateTime start, DateTime end, DateTime from, DateTime to) {
  return end.isAfter(from) && start.isBefore(to);
}

DateTime _addUtcDays(DateTime value, int days) {
  return DateTime.utc(
    value.year,
    value.month,
    value.day + days,
    value.hour,
    value.minute,
    value.second,
    value.millisecond,
    value.microsecond,
  );
}

DateTime _addUtcMonthsClamped(DateTime value, int months) {
  final monthIndex = value.year * 12 + value.month - 1 + months;
  final year = monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  return DateTime.utc(
    year,
    month,
    value.day.clamp(1, lastDay),
    value.hour,
    value.minute,
    value.second,
    value.millisecond,
    value.microsecond,
  );
}

DateTime _displayDate(DateTime value, bool allDay) {
  if (!allDay) return value.toLocal();
  final utc = value.toUtc();
  return DateTime(utc.year, utc.month, utc.day);
}

DateTime? _optionalDateTime(dynamic value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : DateTime.tryParse(text)?.toUtc();
}

T _enumByWireValue<T extends Enum>(
  Iterable<T> values,
  dynamic wireValue,
  T fallback,
) {
  final normalized = wireValue?.toString().toLowerCase();
  return values.cast<T>().firstWhere(
    (value) => value.name.toLowerCase() == normalized,
    orElse: () => fallback,
  );
}

/// 日程日历展示模式。
enum ScheduleViewMode { day, week, month, agenda }

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
      if (revision != null) 'revision': revision,
    };
  }
}

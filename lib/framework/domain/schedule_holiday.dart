import 'package:lunar/lunar.dart';

enum ScheduleHolidayRegion { none, cn, jp }

String scheduleDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class ScheduleHoliday {
  final String date;
  final String name;
  final bool isOffDay;

  const ScheduleHoliday({
    required this.date,
    required this.name,
    required this.isOffDay,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'name': name,
    'isOffDay': isOffDay,
  };
}

/// 按公告年份保存；中国公告允许包含相邻年份的日期。
class HolidayCalendar {
  final String region;
  final int year;
  final String version;
  final List<String> sources;
  final List<ScheduleHoliday> days;

  const HolidayCalendar({
    required this.region,
    required this.year,
    required this.version,
    required this.sources,
    required this.days,
  });

  factory HolidayCalendar.fromJson(Map<String, dynamic> json) {
    final region = json['region'];
    final year = json['year'];
    final rawDays = json['days'];
    if (!['CN', 'JP'].contains(region) ||
        year is! int ||
        year < 1900 ||
        year > 2100 ||
        rawDays is! List ||
        rawDays.length > 370 ||
        json['version'] is! String ||
        json['sources'] is! List ||
        !(json['sources'] as List).every((s) => s is String)) {
      throw const FormatException('Invalid holiday calendar');
    }
    final seen = <String>{};
    if (rawDays.isNotEmpty &&
        (rawDays.length < (region == 'CN' ? 20 : 16) ||
            (json['sources'] as List).isEmpty)) {
      throw const FormatException('Incomplete holiday calendar');
    }
    final days = <ScheduleHoliday>[];
    for (final item in rawDays) {
      if (item is! Map ||
          item['date'] is! String ||
          item['name'] is! String ||
          (item['name'] as String).trim().isEmpty ||
          (item['name'] as String).length > 80 ||
          item['isOffDay'] is! bool ||
          (region == 'JP' && item['isOffDay'] != true)) {
        throw const FormatException('Invalid holiday');
      }
      final key = item['date'] as String;
      final date = DateTime.tryParse(key);
      if (date == null ||
          scheduleDateKey(date) != key ||
          (date.year - year).abs() > (region == 'CN' ? 1 : 0) ||
          !seen.add(key)) {
        throw const FormatException('Invalid or duplicate holiday date');
      }
      days.add(
        ScheduleHoliday(
          date: key,
          name: item['name'] as String,
          isOffDay: item['isOffDay'] as bool,
        ),
      );
    }
    return HolidayCalendar(
      region: region as String,
      year: year,
      version: json['version'] as String,
      sources: List<String>.from(json['sources'] as List),
      days: List.unmodifiable(days),
    );
  }

  ScheduleHoliday? on(DateTime date) {
    final key = scheduleDateKey(date);
    for (final day in days) {
      if (day.date == key) return day;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'region': region,
    'year': year,
    'version': version,
    'sources': sources,
    'days': days.map((d) => d.toJson()).toList(),
  };
}

/// 仅计算农历和传统节日，绝不使用历法库内置的过期调休表。
String scheduleLunarLabel(DateTime day) {
  if (day.year < 1901 || day.year > 2099) return '';
  // 使用年月日构造，避免时区转换使民用日期偏移。
  final date = Solar.fromYmd(day.year, day.month, day.day).getLunar();
  final festivals = date.getFestivals();
  if (festivals.isNotEmpty) return festivals.first;
  return date.getDay() == 1
      ? '${date.getMonthInChinese()}月'
      : date.getDayInChinese();
}

import 'dart:convert';
import 'dart:io';

import 'package:anoxia/framework/domain/schedule_holiday.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HolidayCalendar bundled(String region, int year) => HolidayCalendar.fromJson(
    jsonDecode(File('assets/holidays/$region-$year.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  test('中国2026年休班覆盖国务院公布的完整安排', () {
    final calendar = bundled('CN', 2026);
    final off = <String>[
      ...dates(1, 1, 3),
      ...dates(2, 15, 23),
      ...dates(4, 4, 6),
      ...dates(5, 1, 5),
      ...dates(6, 19, 21),
      ...dates(9, 25, 27),
      ...dates(10, 1, 7),
    ];
    expect(calendar.days.where((d) => d.isOffDay).map((d) => d.date), off);
    expect(calendar.days.where((d) => !d.isOffDay).map((d) => d.date), [
      '2026-01-04',
      '2026-02-14',
      '2026-02-28',
      '2026-05-09',
      '2026-09-20',
      '2026-10-10',
    ]);
  });

  test('日本2026年含振替休日和国民休日，不套用中国补班', () {
    final calendar = bundled('JP', 2026);
    expect(calendar.days.length, 18);
    expect(calendar.on(DateTime(2026, 5, 6))?.name, '休日');
    expect(calendar.on(DateTime(2026, 9, 22))?.name, '休日');
    expect(calendar.on(DateTime(2026, 11, 3))?.name, '文化の日');
    expect(calendar.days.every((d) => d.isOffDay), isTrue);
    expect(calendar.on(DateTime(2026, 2, 14)), isNull);
  });

  test('农历初一、传统节日、闰月按民用日期计算', () {
    expect(scheduleLunarLabel(DateTime(2026, 2, 17)), '春节');
    expect(scheduleLunarLabel(DateTime(2026, 2, 18)), '初二');
    expect(scheduleLunarLabel(DateTime(2026, 9, 25)), '中秋节');
    expect(scheduleLunarLabel(DateTime(2025, 7, 25)), '闰六月');
  });

  test('年度数据拒绝重复日期、无效日期与非布尔休班标记', () {
    final valid = bundled('CN', 2026).toJson();
    expect(
      () => HolidayCalendar.fromJson({
        ...valid,
        'days': [
          {'date': '2026-02-30', 'name': '春节', 'isOffDay': true},
        ],
      }),
      throwsFormatException,
    );
    final day = (valid['days'] as List).first;
    expect(
      () => HolidayCalendar.fromJson({
        ...valid,
        'days': [day, day],
      }),
      throwsFormatException,
    );
    expect(
      () => HolidayCalendar.fromJson({
        ...valid,
        'days': [
          {'date': '2026-01-01', 'name': '元旦', 'isOffDay': 'true'},
        ],
      }),
      throwsFormatException,
    );
  });
}

List<String> dates(int month, int from, int to) => [
  for (var day = from; day <= to; day++)
    '2026-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
];

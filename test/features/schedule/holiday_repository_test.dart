import 'dart:convert';
import 'dart:io';
import 'package:anoxia/data/repositories/holiday_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final snapshot =
      jsonDecode(File('assets/holidays/CN-2026.json').readAsStringSync())
          as Map<String, dynamic>;
  Map<String, dynamic> empty(int year) => {
    'region': 'CN',
    'year': year,
    'version': '',
    'sources': <String>[],
    'days': <dynamic>[],
  };

  test('有效更新持久化，六小时内不重复请求，离线继续显示', () async {
    SharedPreferences.setMockInitialValues(const {});
    var calls = 0;
    final repository = HolidayRepositoryImpl(
      fetch: (region, year) async {
        calls++;
        return year == 2026 ? {...snapshot, 'version': 'updated'} : empty(year);
      },
    );
    await repository.refresh('CN', 2026);
    final cached = await repository.cached('CN', 2026);
    expect(cached.singleWhere((c) => c.year == 2026).version, 'updated');
    await repository.refresh('CN', 2026);
    expect(calls, 3);
    final prefs = await SharedPreferences.getInstance();
    for (final year in [2025, 2026, 2027]) {
      await prefs.remove('schedule.holidays.CN.$year.checked');
    }
    final offline = HolidayRepositoryImpl(
      fetch: (_, _) async => throw const SocketException('offline'),
    );
    expect(
      (await offline.refresh(
        'CN',
        2026,
      )).singleWhere((c) => c.year == 2026).version,
      'updated',
    );
  });

  test('空响应、错误地区、截断数据都不能覆盖有效缓存', () async {
    for (final invalid in [
      empty(2026),
      {...snapshot, 'region': 'JP'},
      {
        ...snapshot,
        'days': [(snapshot['days'] as List).first],
      },
    ]) {
      SharedPreferences.setMockInitialValues({
        'schedule.holidays.CN.2026': jsonEncode(snapshot),
      });
      final repository = HolidayRepositoryImpl(
        fetch: (_, year) async => year == 2026 ? invalid : empty(year),
      );
      final calendars = await repository.refresh('CN', 2026);
      expect(calendars.singleWhere((c) => c.year == 2026).days.length, 39);
    }
  });
}

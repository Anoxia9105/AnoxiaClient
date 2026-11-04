import 'dart:convert';

import 'package:anoxia/domain/repositories/holiday_repository.dart';
import 'package:anoxia/framework/domain/schedule_holiday.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HolidayRepositoryImpl implements HolidayRepository {
  final Future<dynamic> Function(String region, int year) _fetch;
  final Map<(String, int), Future<void>> _refreshing = {};
  static final _bundledAssets = AssetManifest.loadFromAssetBundle(
    rootBundle,
  ).then((manifest) => manifest.listAssets().toSet());

  HolidayRepositoryImpl({Future<dynamic> Function(String, int)? fetch})
    : _fetch = fetch ?? _fetchRemote;

  static Future<dynamic> _fetchRemote(String region, int year) async {
    final response = await DioClient().get(
      '/schedule/holidays',
      queryParameters: {'region': region, 'year': year},
    );
    final body = response.data;
    if (body is! Map || body['code'] != 200 || body['data'] is! Map) {
      throw const FormatException('Invalid holiday response');
    }
    return body['data'];
  }

  // 包含网格跨年的日期及中国下一年公告对上一年十二月的修订。
  List<int> _years(int year) => [year - 1, year, year + 1];

  @override
  Future<List<HolidayCalendar>> cached(String region, int year) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <HolidayCalendar>[];
    for (final y in _years(year)) {
      HolidayCalendar? calendar;
      try {
        final raw = prefs.getString('schedule.holidays.$region.$y');
        if (raw != null) calendar = _parse(raw, region, y);
      } catch (_) {
        /* 缓存损坏时回退内置快照。 */
      }
      if (calendar == null) {
        try {
          final path = 'assets/holidays/$region-$y.json';
          if ((await _bundledAssets).contains(path)) {
            calendar = _parse(await rootBundle.loadString(path), region, y);
          }
        } catch (_) {
          /* 未公布年份保持空白。 */
        }
      }
      if (calendar != null) result.add(calendar);
    }
    return result;
  }

  @override
  Future<List<HolidayCalendar>> refresh(String region, int year) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait(
      _years(year).map((y) {
        final key = (region, y);
        return _refreshing[key] ??= _refreshYear(prefs, region, y).whenComplete(
          () {
            _refreshing.remove(key);
          },
        );
      }),
    );
    return cached(region, year);
  }

  Future<void> _refreshYear(
    SharedPreferences prefs,
    String region,
    int year,
  ) async {
    final key = 'schedule.holidays.$region.$year';
    final checked = prefs.getInt('$key.checked') ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - checked <
        const Duration(hours: 6).inMilliseconds) {
      return;
    }
    try {
      final calendar = _parse(
        jsonEncode(await _fetch(region, year)),
        region,
        year,
      );
      // 空响应表示尚未公布，不覆盖已核验的快照。
      if (calendar.days.isNotEmpty) {
        await prefs.setString(key, jsonEncode(calendar.toJson()));
      }
      await prefs.setInt('$key.checked', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      /* 网络失败保留旧数据，不影响个人日程。 */
    }
  }

  HolidayCalendar _parse(String raw, String region, int year) {
    final calendar = HolidayCalendar.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    if (calendar.region != region || calendar.year != year) {
      throw const FormatException('Holiday identity mismatch');
    }
    return calendar;
  }
}

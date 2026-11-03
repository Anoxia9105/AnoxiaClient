// 本地视觉验收：flutter run -d web-server -t test/manual/schedule_preview.dart --web-port 7357
// 使用真实页面、语言包、主题与内置假期；个人日程仅存内存，不访问真实账号。
import 'dart:convert';
import 'package:anoxia/domain/repositories/holiday_repository.dart';
import 'package:anoxia/domain/repositories/schedule_repository.dart';
import 'package:anoxia/features/schedule/presentation/pages/schedule_page.dart';
import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:anoxia/framework/domain/schedule_holiday.dart';
import 'package:anoxia/framework/provider/core/schedule_repository_provider.dart';
import 'package:anoxia/framework/provider/schedule/schedule_holidays.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final snapshots = <HolidayCalendar>[];
  for (final file in ['CN-2025', 'CN-2026', 'JP-2025', 'JP-2026', 'JP-2027']) {
    snapshots.add(
      HolidayCalendar.fromJson(
        jsonDecode(await rootBundle.loadString('assets/holidays/$file.json'))
            as Map<String, dynamic>,
      ),
    );
  }
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('zh'), Locale('en'), Locale('ja')],
      startLocale: const Locale('zh'),
      path: 'assets/i18n',
      child: ProviderScope(
        overrides: [
          scheduleRepositoryProvider.overrideWithValue(_Events()),
          holidayRepositoryProvider.overrideWithValue(_Holidays(snapshots)),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            theme: AppTheme.getTheme(),
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            home: const SchedulePage(),
          ),
        ),
      ),
    ),
  );
}

class _Holidays implements HolidayRepository {
  final List<HolidayCalendar> snapshots;
  _Holidays(this.snapshots);
  @override
  Future<List<HolidayCalendar>> cached(String region, int year) async =>
      snapshots
          .where((c) => c.region == region && (c.year - year).abs() <= 1)
          .toList();
  @override
  Future<List<HolidayCalendar>> refresh(String region, int year) =>
      cached(region, year);
}

class _Events implements ScheduleRepository {
  final events = <ScheduleEvent>[];
  @override
  Future<List<ScheduleEvent>> list({
    required DateTime from,
    required DateTime to,
  }) async => List.of(events);
  @override
  Future<ScheduleEvent> create(ScheduleEventDraft draft) async {
    final event = ScheduleEvent(
      id: events.length + 1,
      title: draft.title,
      startAt: draft.startAt,
      endAt: draft.endAt,
      timeZone: draft.timeZone,
      allDay: draft.allDay,
      revision: 1,
      color: draft.color,
    );
    events.add(event);
    return event;
  }

  @override
  Future<void> delete(int id) async => events.removeWhere((e) => e.id == id);
  @override
  Future<ScheduleEvent> update(int id, ScheduleEventDraft draft) async {
    await delete(id);
    return create(draft);
  }
}

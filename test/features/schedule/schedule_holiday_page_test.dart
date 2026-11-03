import 'dart:convert';
import 'dart:io';

import 'package:anoxia/domain/repositories/holiday_repository.dart';
import 'package:anoxia/domain/repositories/schedule_repository.dart';
import 'package:anoxia/features/schedule/presentation/pages/schedule_page.dart';
import 'package:anoxia/features/schedule/presentation/widgets/schedule_month_view.dart';
import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:anoxia/framework/domain/schedule_holiday.dart';
import 'package:anoxia/framework/provider/core/schedule_repository_provider.dart';
import 'package:anoxia/framework/provider/schedule/schedule_holidays.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('矮屏仍显示日程数量入口，点击可看到新建日程', (tester) async {
    final repository = MemoryScheduleRepository();
    repository.events.add(
      ScheduleEvent(
        id: 1,
        title: '春节家庭聚餐',
        startAt: DateTime.utc(2026, 2, 17),
        endAt: DateTime.utc(2026, 2, 18),
        timeZone: 'UTC',
        allDay: true,
        revision: 1,
      ),
    );
    await pumpCalendar(tester, width: 320, height: 568, repository: repository);
    await moveTo(tester, DateTime(2026, 2));
    expect(find.text('+1'), findsOneWidget);
    await tester.tap(find.text('+1'));
    await tester.pumpAndSettle();
    expect(find.text('春节家庭聚餐'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets('新建日程与农历假期共存 ${width.toInt()}px', (tester) async {
      final repository = MemoryScheduleRepository();
      await pumpCalendar(tester, width: width, repository: repository);
      await moveTo(tester, DateTime(2026, 2));
      final cell = find.byKey(
        ValueKey(
          'schedule-month-day-${DateTime(2026, 2, 17).toIso8601String()}',
        ),
      );
      expect(
        find.descendant(of: cell, matching: find.text('春节')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: cell, matching: find.text('休')),
        findsOneWidget,
      );
      await tester.tap(cell);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '春节家庭聚餐与朋友见面');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(repository.events.length, 1);
      expect(
        find.descendant(of: cell, matching: find.textContaining('春节家庭聚餐')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: cell, matching: find.text('春节')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: cell, matching: find.text('休')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  }

  testWidgets('地区独立保存，切换语言不改变假期且未公布年份留空', (tester) async {
    await pumpCalendar(
      tester,
      width: 768,
      repository: MemoryScheduleRepository(),
    );
    await tester.tap(find.byKey(const ValueKey('schedule-calendar-options')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('日本'));
    await tester.pumpAndSettle();
    await moveTo(tester, DateTime(2026, 11));
    final day = find.byKey(
      ValueKey('schedule-month-day-${DateTime(2026, 11, 3).toIso8601String()}'),
    );
    expect(
      find.descendant(of: day, matching: find.text('文化日')),
      findsOneWidget,
    );
    final context = tester.element(find.byType(SchedulePage));
    await context.setLocale(const Locale('en'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: day, matching: find.text('Culture Day')),
      findsOneWidget,
    );
    expect(
      (await SharedPreferences.getInstance()).getString(
        'schedule.holidayRegion',
      ),
      'jp',
    );
    await moveTo(tester, DateTime(2028, 11));
    expect(
      tester
          .widget<ScheduleMonthView>(find.byType(ScheduleMonthView))
          .holidays
          .keys
          .where((key) => key.startsWith('2028-')),
      isEmpty,
    );
    expect(find.textContaining('暂无'), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('同日多条日程可以展开访问且不溢出', (tester) async {
    final repository = MemoryScheduleRepository();
    for (var i = 0; i < 5; i++) {
      repository.events.add(
        ScheduleEvent(
          id: i,
          title: '聚餐日程$i',
          startAt: DateTime.utc(2026, 2, 17),
          endAt: DateTime.utc(2026, 2, 18),
          timeZone: 'UTC',
          allDay: true,
          revision: 1,
        ),
      );
    }
    await pumpCalendar(tester, width: 320, repository: repository);
    await moveTo(tester, DateTime(2026, 2));
    await tester.tap(find.textContaining('另有').first);
    await tester.pumpAndSettle();
    expect(find.text('聚餐日程4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}

Future<void> pumpCalendar(
  WidgetTester tester, {
  required double width,
  double height = 900,
  required MemoryScheduleRepository repository,
}) async {
  SharedPreferences.setMockInitialValues(const {});
  await EasyLocalization.ensureInitialized();
  for (final locale in ['zh', 'en', 'ja']) {
    await initializeDateFormatting(locale);
  }
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('zh'), Locale('en'), Locale('ja')],
      startLocale: const Locale('zh'),
      fallbackLocale: const Locale('zh'),
      path: 'assets/i18n',
      assetLoader: const DiskAssetLoader(),
      child: ProviderScope(
        overrides: [
          scheduleRepositoryProvider.overrideWithValue(repository),
          holidayRepositoryProvider.overrideWithValue(DiskHolidayRepository()),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const SchedulePage(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> moveTo(WidgetTester tester, DateTime month) async {
  final focused = tester
      .widget<ScheduleMonthView>(find.byType(ScheduleMonthView))
      .focusedDay;
  final difference =
      (month.year - focused.year) * 12 + month.month - focused.month;
  for (var i = 0; i < difference.abs(); i++) {
    await tester.tap(
      find.byIcon(difference > 0 ? Icons.chevron_right : Icons.chevron_left),
    );
    await tester.pumpAndSettle();
  }
}

class DiskAssetLoader extends AssetLoader {
  const DiskAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) =>
      Future.value(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map<String, dynamic>,
      );
}

class DiskHolidayRepository implements HolidayRepository {
  @override
  Future<List<HolidayCalendar>> cached(String region, int year) async => [
    for (final y in [year - 1, year, year + 1])
      if (File('assets/holidays/$region-$y.json').existsSync())
        HolidayCalendar.fromJson(
          jsonDecode(File('assets/holidays/$region-$y.json').readAsStringSync())
              as Map<String, dynamic>,
        ),
  ];
  @override
  Future<List<HolidayCalendar>> refresh(String region, int year) =>
      cached(region, year);
}

class MemoryScheduleRepository implements ScheduleRepository {
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
  Future<void> delete(int id) async =>
      events.removeWhere((event) => event.id == id);
  @override
  Future<ScheduleEvent> update(int id, ScheduleEventDraft draft) =>
      throw UnimplementedError();
}

import 'package:anoxia/features/schedule/presentation/widgets/schedule_timeline_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('day and week timelines render at desktop minimum width', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('zh');
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> pumpTimeline(bool week) {
      return tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('zh'),
          startLocale: const Locale('zh'),
          child: MaterialApp(
            home: Scaffold(
              body: ScheduleTimelineView(
                focusedDay: DateTime(2026, 9, 22),
                week: week,
                occurrences: const [],
                onEmptySlotTap: (_) {},
                onEventTap: (_) {},
                onOccurrenceChanged: (_, _, _) async {},
              ),
            ),
          ),
        ),
      );
    }

    await pumpTimeline(false);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('schedule-day-view')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpTimeline(true);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('schedule-week-view')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

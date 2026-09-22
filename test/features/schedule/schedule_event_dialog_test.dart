import 'package:anoxia/features/schedule/presentation/widgets/schedule_event_dialog.dart';
import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('turning off all-day creates a valid one-hour time range', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('zh');
    ScheduleEventDraft? savedDraft;
    final event = ScheduleEvent(
      id: 1,
      title: '全天日程',
      startAt: DateTime.utc(2026, 9, 22),
      endAt: DateTime.utc(2026, 9, 23),
      timeZone: 'UTC',
      allDay: true,
      revision: 1,
    );

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('zh'),
        startLocale: const Locale('zh'),
        useFallbackTranslations: true,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showScheduleEventDialog(
                context,
                event: event,
                onSave: (draft) async => savedDraft = draft,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.text('schedule_save'));
    await tester.pumpAndSettle();

    expect(savedDraft, isNotNull);
    expect(savedDraft!.allDay, isFalse);
    expect(
      savedDraft!.endAt.difference(savedDraft!.startAt),
      const Duration(hours: 1),
    );
  });
}

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
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    expect(
      tester.getSize(find.byKey(const ValueKey('schedule-event-dialog'))),
      const Size(920, 720),
    );
    expect(
      find.byKey(const ValueKey('schedule-dialog-primary-column')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('schedule-dialog-settings-column')),
      findsOneWidget,
    );
    expect(find.byType(MenuAnchor), findsNWidgets(2));
    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    expect(dialog.backgroundColor!.a, 1);
    final titleField = tester.element(find.byType(TextFormField).first);
    expect(Theme.of(titleField).inputDecorationTheme.filled, isFalse);
    final allDaySwitch = find.byKey(const ValueKey('schedule-all-day'));
    await tester.ensureVisible(allDaySwitch);
    await tester.tap(allDaySwitch);
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

  testWidgets('手机端使用主题色独立页面且可返回', (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('zh');
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
              onPressed: () =>
                  showScheduleEventDialog(context, onSave: (_) async {}),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('schedule-event-dialog')), findsNothing);
    expect(find.byKey(const ValueKey('schedule-event-page')), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    final pageContext = tester.element(
      find.byKey(const ValueKey('schedule-event-page')),
    );
    final theme = Theme.of(pageContext);
    expect(theme.scaffoldBackgroundColor.a, 1);
    expect(theme.appBarTheme.backgroundColor, theme.colorScheme.surface);
    expect(theme.inputDecorationTheme.filled, isFalse);
    expect(
      find.byKey(const ValueKey('schedule-dialog-mobile-content')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('schedule-dialog-footer')),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schedule-event-page')), findsNothing);
  });

  testWidgets('saves the selected color and reminder', (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('zh');
    ScheduleEventDraft? savedDraft;
    final event = ScheduleEvent(
      id: 2,
      title: '项目评审',
      startAt: DateTime.utc(2026, 9, 22, 1),
      endAt: DateTime.utc(2026, 9, 22, 2),
      timeZone: 'UTC',
      allDay: false,
      revision: 1,
      color: '#4F6BED',
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
    await tester.tap(find.byKey(const ValueKey('schedule-color-#D14343')));
    await tester.tap(find.byKey(const ValueKey('schedule-reminder')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('schedule_reminder_15').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('schedule_save'));
    await tester.tap(find.text('schedule_save'));
    await tester.pumpAndSettle();

    expect(savedDraft?.color, '#D14343');
    expect(savedDraft?.reminderMinutes, 15);
  });

  testWidgets('preserves weekly recurrence when editing a series', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('zh');
    ScheduleEventDraft? savedDraft;
    final event = ScheduleEvent(
      id: 3,
      title: '团队同步',
      startAt: DateTime.utc(2026, 9, 21, 1),
      endAt: DateTime.utc(2026, 9, 21, 2),
      timeZone: 'UTC',
      allDay: false,
      revision: 1,
      recurrence: ScheduleRecurrence(
        frequency: ScheduleRecurrenceFrequency.weekly,
        interval: 2,
        weekdays: const [DateTime.monday, DateTime.wednesday],
        endType: ScheduleRecurrenceEndType.until,
        until: DateTime.utc(2026, 12, 31),
      ),
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
    expect(find.byKey(const ValueKey('schedule-recurrence')), findsOneWidget);
    await tester.ensureVisible(find.text('schedule_save'));
    await tester.tap(find.text('schedule_save'));
    await tester.pumpAndSettle();

    expect(
      savedDraft?.recurrence?.frequency,
      ScheduleRecurrenceFrequency.weekly,
    );
    expect(savedDraft?.recurrence?.interval, 2);
    expect(savedDraft?.recurrence?.weekdays, [1, 3]);
    expect(savedDraft?.recurrence?.endType, ScheduleRecurrenceEndType.until);
  });
}

import 'package:anoxia/domain/repositories/schedule_repository.dart';
import 'package:anoxia/features/schedule/presentation/pages/schedule_page.dart';
import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:anoxia/framework/provider/core/schedule_repository_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('month view renders without a runtime type error', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('zh');
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('zh'),
        startLocale: const Locale('zh'),
        child: ProviderScope(
          overrides: [
            scheduleRepositoryProvider.overrideWithValue(
              _EmptyScheduleRepository(),
            ),
          ],
          child: const MaterialApp(home: SchedulePage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SchedulePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _EmptyScheduleRepository implements ScheduleRepository {
  @override
  Future<List<ScheduleEvent>> list({
    required DateTime from,
    required DateTime to,
  }) async => const [];

  @override
  Future<ScheduleEvent> create(ScheduleEventDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<ScheduleEvent> update(int id, ScheduleEventDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(int id) {
    throw UnimplementedError();
  }
}

import 'package:anoxia/domain/repositories/schedule_repository.dart';
import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:anoxia/framework/provider/core/schedule_repository_provider.dart';
import 'package:anoxia/framework/provider/schedule/schedule_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'merges the calendar and quick-list windows without duplicates',
    () async {
      final repository = _FakeScheduleRepository([
        [_event(1, DateTime.utc(2026, 9, 22, 1))],
        [
          _event(1, DateTime.utc(2026, 9, 22, 1)),
          _event(2, DateTime.utc(2026, 9, 23, 1)),
        ],
      ]);
      final container = ProviderContainer(
        overrides: [scheduleRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(scheduleServiceProvider.notifier)
          .load(
            ScheduleRange(
              from: DateTime.utc(2026, 9, 22),
              to: DateTime.utc(2026, 9, 23),
            ),
            supplement: ScheduleRange(
              from: DateTime.utc(2026, 9, 22),
              to: DateTime.utc(2026, 9, 30),
            ),
          );

      final events = container.read(scheduleServiceProvider).requireValue;
      expect(repository.listCalls, 2);
      expect(events.map((event) => event.id), [1, 2]);
    },
  );

  test(
    'skips the quick-list request when the view already contains it',
    () async {
      final repository = _FakeScheduleRepository([const []]);
      final container = ProviderContainer(
        overrides: [scheduleRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(scheduleServiceProvider.notifier)
          .load(
            ScheduleRange(
              from: DateTime.utc(2026, 9, 1),
              to: DateTime.utc(2026, 10, 1),
            ),
            supplement: ScheduleRange(
              from: DateTime.utc(2026, 9, 22),
              to: DateTime.utc(2026, 9, 30),
            ),
          );

      expect(repository.listCalls, 1);
    },
  );

  test('restores the previous event when rescheduling fails', () async {
    final original = _event(7, DateTime.utc(2026, 9, 22, 1));
    final repository = _FakeScheduleRepository([
      [original],
    ], failUpdate: true);
    final container = ProviderContainer(
      overrides: [scheduleRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(scheduleServiceProvider.notifier);
    final range = ScheduleRange(
      from: DateTime.utc(2026, 9, 22),
      to: DateTime.utc(2026, 9, 23),
    );
    await notifier.load(range);

    await expectLater(
      notifier.reschedule(
        original,
        DateTime.utc(2026, 9, 22, 3),
        DateTime.utc(2026, 9, 22, 4),
      ),
      throwsStateError,
    );

    final restored = container
        .read(scheduleServiceProvider)
        .requireValue
        .single;
    expect(restored.startAt, original.startAt);
    expect(restored.endAt, original.endAt);
  });
}

ScheduleEvent _event(int id, DateTime startAt) {
  return ScheduleEvent(
    id: id,
    title: 'event $id',
    startAt: startAt,
    endAt: startAt.add(const Duration(hours: 1)),
    timeZone: 'UTC',
    allDay: false,
    revision: 1,
  );
}

class _FakeScheduleRepository implements ScheduleRepository {
  final List<List<ScheduleEvent>> responses;
  final bool failUpdate;
  int listCalls = 0;

  _FakeScheduleRepository(this.responses, {this.failUpdate = false});

  @override
  Future<List<ScheduleEvent>> list({
    required DateTime from,
    required DateTime to,
  }) async {
    return responses[listCalls++];
  }

  @override
  Future<ScheduleEvent> create(ScheduleEventDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<ScheduleEvent> update(int id, ScheduleEventDraft draft) async {
    if (failUpdate) throw StateError('update failed');
    return _event(id, draft.startAt);
  }

  @override
  Future<void> delete(int id) {
    throw UnimplementedError();
  }
}

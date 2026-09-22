import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:anoxia/framework/provider/core/schedule_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_service.g.dart';

@Riverpod(keepAlive: true)
class ScheduleService extends _$ScheduleService {
  ScheduleRange? _range;
  ScheduleRange? _supplementRange;
  int _requestSerial = 0;

  @override
  FutureOr<List<ScheduleEvent>> build() => const [];

  Future<void> load(
    ScheduleRange range, {
    ScheduleRange? supplement,
    bool quiet = false,
  }) async {
    _range = range;
    _supplementRange = supplement;
    final requestSerial = ++_requestSerial;
    if (!quiet) state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final repository = ref.read(scheduleRepositoryProvider);
      final requests = <Future<List<ScheduleEvent>>>[
        repository.list(from: range.from, to: range.to),
        if (supplement != null && !_contains(range, supplement))
          repository.list(from: supplement.from, to: supplement.to),
      ];
      final batches = await Future.wait(requests);
      final merged = <int, ScheduleEvent>{};
      for (final event in batches.expand((batch) => batch)) {
        merged[event.id] = event;
      }
      return merged.values.toList(growable: false)
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
    });
    if (!ref.mounted || requestSerial != _requestSerial) return;
    state = result;
  }

  Future<void> refresh() async {
    final range = _range;
    if (range != null) {
      await load(range, supplement: _supplementRange, quiet: true);
    }
  }

  Future<ScheduleEvent> create(ScheduleEventDraft draft) async {
    final result = await ref.read(scheduleRepositoryProvider).create(draft);
    await refresh();
    return result;
  }

  Future<ScheduleEvent> updateEvent(int id, ScheduleEventDraft draft) async {
    final result = await ref.read(scheduleRepositoryProvider).update(id, draft);
    await refresh();
    return result;
  }

  Future<void> deleteEvent(int id) async {
    await ref.read(scheduleRepositoryProvider).delete(id);
    await refresh();
  }

  bool _contains(ScheduleRange outer, ScheduleRange inner) {
    return !inner.from.isBefore(outer.from) && !inner.to.isAfter(outer.to);
  }
}

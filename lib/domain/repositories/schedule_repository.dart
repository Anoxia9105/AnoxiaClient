import 'package:anoxia/framework/domain/schedule_event.dart';

abstract interface class ScheduleRepository {
  Future<List<ScheduleEvent>> list({
    required DateTime from,
    required DateTime to,
  });

  Future<ScheduleEvent> create(ScheduleEventDraft draft);

  Future<ScheduleEvent> update(int id, ScheduleEventDraft draft);

  Future<void> delete(int id);
}

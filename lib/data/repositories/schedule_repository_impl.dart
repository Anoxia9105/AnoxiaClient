import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/repositories/schedule_repository.dart';
import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:anoxia/framework/network/dio_client.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  @override
  Future<List<ScheduleEvent>> list({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await DioClient().get(
      API.scheduleEvents,
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );
    final data = _extractData(response);
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => ScheduleEvent.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  @override
  Future<ScheduleEvent> create(ScheduleEventDraft draft) async {
    final response = await DioClient().post(
      API.scheduleEvents,
      data: draft.toJson(),
    );
    return _extractEvent(response);
  }

  @override
  Future<ScheduleEvent> update(int id, ScheduleEventDraft draft) async {
    final response = await DioClient().put(
      '${API.scheduleEvents}/$id',
      data: draft.toJson(),
    );
    return _extractEvent(response);
  }

  @override
  Future<void> delete(int id) async {
    await DioClient().delete('${API.scheduleEvents}/$id');
  }

  dynamic _extractData(dynamic response) {
    final body = response.data;
    return body is Map ? body['data'] : null;
  }

  ScheduleEvent _extractEvent(dynamic response) {
    final data = _extractData(response);
    if (data is Map) {
      return ScheduleEvent.fromJson(Map<String, dynamic>.from(data));
    }
    throw const FormatException('schedule_event_response_invalid');
  }
}

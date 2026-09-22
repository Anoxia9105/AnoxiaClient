import 'package:anoxia/data/repositories/schedule_repository_impl.dart';
import 'package:anoxia/domain/repositories/schedule_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl();
});

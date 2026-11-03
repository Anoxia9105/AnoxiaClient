import 'package:anoxia/data/repositories/holiday_repository_impl.dart';
import 'package:anoxia/domain/repositories/holiday_repository.dart';
import 'package:anoxia/framework/domain/schedule_holiday.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_holidays.g.dart';

@riverpod
HolidayRepository holidayRepository(Ref ref) => HolidayRepositoryImpl();

@riverpod
Stream<Map<String, ScheduleHoliday>> scheduleHolidays(
  Ref ref,
  ScheduleHolidayRegion region,
  int year,
) async* {
  if (region == ScheduleHolidayRegion.none) {
    yield const {};
    return;
  }
  final repository = ref.watch(holidayRepositoryProvider);
  Map<String, ScheduleHoliday> merge(List<HolidayCalendar> calendars) => {
    for (final calendar in [
      ...calendars,
    ]..sort((a, b) => a.year.compareTo(b.year)))
      for (final day in calendar.days) day.date: day,
  };
  final code = region.name.toUpperCase();
  yield merge(await repository.cached(code, year));
  yield merge(await repository.refresh(code, year));
}

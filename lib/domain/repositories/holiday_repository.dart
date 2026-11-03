import 'package:anoxia/framework/domain/schedule_holiday.dart';

abstract interface class HolidayRepository {
  Future<List<HolidayCalendar>> cached(String region, int year);
  Future<List<HolidayCalendar>> refresh(String region, int year);
}

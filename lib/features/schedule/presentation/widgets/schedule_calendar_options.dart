import 'package:anoxia/framework/domain/schedule_holiday.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ScheduleCalendarOptions extends StatelessWidget {
  final ScheduleHolidayRegion region;
  final bool showLunar;
  final ValueChanged<ScheduleHolidayRegion> onRegionChanged;
  final ValueChanged<bool> onLunarChanged;

  const ScheduleCalendarOptions({
    super.key,
    required this.region,
    required this.showLunar,
    required this.onRegionChanged,
    required this.onLunarChanged,
  });

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    key: const ValueKey('schedule-calendar-options'),
    tooltip: 'schedule_calendar_options'.tr(),
    icon: const Icon(Icons.tune),
    onSelected: (value) {
      if (value == 'lunar') {
        onLunarChanged(!showLunar);
        return;
      }
      onRegionChanged(ScheduleHolidayRegion.values.byName(value));
    },
    itemBuilder: (_) => [
      PopupMenuItem(
        enabled: false,
        child: Text('schedule_holiday_region'.tr()),
      ),
      for (final item in ScheduleHolidayRegion.values)
        CheckedPopupMenuItem(
          value: item.name,
          checked: item == region,
          child: Text('schedule_region_${item.name}'.tr()),
        ),
      const PopupMenuDivider(),
      CheckedPopupMenuItem(
        value: 'lunar',
        checked: showLunar,
        child: Text('schedule_show_lunar'.tr()),
      ),
    ],
  );
}

String scheduleHolidayName(String name) {
  const names = {
    '元旦': 'new_year',
    '春节': 'spring_festival',
    '清明节': 'qingming',
    '劳动节': 'labour_day',
    '端午节': 'dragon_boat',
    '中秋节': 'mid_autumn',
    '国庆节': 'national_day',
    '元日': 'jp_new_year',
    '成人の日': 'coming_of_age',
    '建国記念の日': 'foundation',
    '天皇誕生日': 'emperor_birthday',
    '春分の日': 'vernal_equinox',
    '昭和の日': 'showa',
    '憲法記念日': 'constitution',
    'みどりの日': 'greenery',
    'こどもの日': 'children',
    '海の日': 'marine',
    '山の日': 'mountain',
    '敬老の日': 'respect_aged',
    '秋分の日': 'autumn_equinox',
    'スポーツの日': 'sports',
    '文化の日': 'culture',
    '勤労感謝の日': 'labour_thanks',
    '休日': 'jp_holiday',
  };
  final key = names[name];
  return key == null ? name : 'schedule_holiday_$key'.tr();
}

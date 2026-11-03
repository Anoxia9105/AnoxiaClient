import 'package:anoxia/framework/theme/composer_frame.dart';
import 'dart:math' as math;
import 'package:anoxia/features/schedule/presentation/schedule_calendar_layout.dart';
import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:anoxia/framework/domain/schedule_holiday.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'schedule_calendar_options.dart';

class ScheduleMonthView extends StatelessWidget {
  final DateTime focusedDay;
  final List<ScheduleOccurrence> occurrences;
  final Map<String, ScheduleHoliday> holidays;
  final bool showLunar;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<ScheduleEvent> onEventTap;

  const ScheduleMonthView({
    super.key,
    required this.focusedDay,
    required this.occurrences,
    this.holidays = const {},
    this.showLunar = false,
    required this.onDayTap,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final days = scheduleMonthGridDays(focusedDay);
    final colors = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('schedule-month-view'),
      children: [
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            border: Border(bottom: ComposerFrame.side(colors)),
          ),
          child: Row(
            children: List.generate(
              7,
              (index) => Expanded(
                child: Center(
                  child: Text(
                    DateFormat.E(
                      context.locale.toString(),
                    ).format(DateTime(2024, 1, 1 + index)),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: constraints.maxHeight / 6,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) => _MonthDayCell(
                day: days[index],
                currentMonth: focusedDay.month,
                holiday: holidays[scheduleDateKey(days[index])],
                showLunar: showLunar,
                occurrences: occurrences
                    .where((o) => scheduleOccurrenceIsOnDay(o, days[index]))
                    .toList(growable: false),
                onDayTap: onDayTap,
                onEventTap: onEventTap,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  final DateTime day;
  final int currentMonth;
  final ScheduleHoliday? holiday;
  final bool showLunar;
  final List<ScheduleOccurrence> occurrences;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<ScheduleEvent> onEventTap;

  const _MonthDayCell({
    required this.day,
    required this.currentMonth,
    required this.holiday,
    required this.showLunar,
    required this.occurrences,
    required this.onDayTap,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isToday = DateUtils.isSameDay(DateTime.now(), day);
    final holidayName = holiday == null
        ? ''
        : scheduleHolidayName(holiday!.name);
    final lunar = showLunar ? scheduleLunarLabel(day) : '';
    final subtitle = holidayName.isNotEmpty ? holidayName : lunar;
    return InkWell(
      key: ValueKey('schedule-month-day-${day.toIso8601String()}'),
      onTap: () => onDayTap(day),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 3, 4, 2),
        decoration: BoxDecoration(
          border: Border(
            right: ComposerFrame.side(colors),
            bottom: ComposerFrame.side(colors),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showSubtitle =
                subtitle.isNotEmpty && constraints.maxHeight >= 45;
            final headerHeight = constraints.maxHeight.clamp(0.0, 27.0);
            final rowHeight = MediaQuery.textScalerOf(context).scale(14) + 6;
            final showHeaderCount =
                occurrences.isNotEmpty &&
                constraints.maxHeight - headerHeight - (showSubtitle ? 16 : 0) <
                    rowHeight;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: headerHeight,
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 27,
                          height: 27,
                          alignment: Alignment.center,
                          decoration: isToday
                              ? BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isToday
                                  ? colors.onPrimary
                                  : day.month == currentMonth
                                  ? colors.onSurface
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (holiday != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Tooltip(
                              message: holidayName,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: holiday!.isOffDay
                                      ? colors.errorContainer
                                      : colors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  (holiday!.isOffDay
                                          ? 'schedule_day_off'
                                          : 'schedule_workday')
                                      .tr(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    height: 1.2,
                                    color: holiday!.isOffDay
                                        ? colors.onErrorContainer
                                        : colors.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (showHeaderCount)
                          Tooltip(
                            message: 'schedule_more'.tr(
                              args: ['${occurrences.length}'],
                            ),
                            child: InkWell(
                              onTap: () => _showDayEvents(context),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Text(
                                  '+${occurrences.length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (showSubtitle)
                  SizedBox(
                    height: 16,
                    child: Tooltip(
                      message: [
                        holidayName,
                        lunar,
                      ].where((s) => s.isNotEmpty).toSet().join(' · '),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.4,
                          color: holiday != null
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, eventConstraints) {
                      final rowHeight =
                          MediaQuery.textScalerOf(context).scale(14) + 6;
                      final slots = (eventConstraints.maxHeight / rowHeight)
                          .floor()
                          .clamp(0, 3);
                      final visible = occurrences.length > slots
                          ? math.max(0, slots - 1)
                          : slots;
                      final hidden = occurrences.length - visible;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final occurrence in occurrences.take(visible))
                            SizedBox(
                              height: rowHeight,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: _MonthEvent(
                                  occurrence: occurrence,
                                  onTap: () => onEventTap(occurrence.event),
                                ),
                              ),
                            ),
                          if (hidden > 0 && slots > 0)
                            SizedBox(
                              height: rowHeight,
                              child: InkWell(
                                onTap: () => _showDayEvents(context),
                                child: Text(
                                  'schedule_more'.tr(args: ['$hidden']),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDayEvents(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(
                DateFormat.yMMMd(context.locale.toString()).format(day),
              ),
            ),
            for (final occurrence in occurrences)
              ListTile(
                title: Text(occurrence.event.title),
                subtitle: Text(
                  occurrence.event.allDay
                      ? 'schedule_all_day'.tr()
                      : DateFormat.Hm(
                          context.locale.toString(),
                        ).format(scheduleOccurrenceDisplayStart(occurrence)),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onEventTap(occurrence.event);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthEvent extends StatelessWidget {
  final ScheduleOccurrence occurrence;
  final VoidCallback onTap;
  const _MonthEvent({required this.occurrence, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _parseScheduleColor(
      occurrence.event.color,
      Theme.of(context).colorScheme.primary,
    );
    final start = scheduleOccurrenceDisplayStart(occurrence);
    final prefix = occurrence.event.allDay
        ? ''
        : '${DateFormat.Hm(context.locale.toString()).format(start)} ';
    return Tooltip(
      message: occurrence.event.title,
      child: Material(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 3)),
            ),
            child: Text(
              '$prefix${occurrence.event.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, height: 1.4, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

Color _parseScheduleColor(String? value, Color fallback) {
  final hex = value?.replaceFirst('#', '');
  final parsed = hex == null ? null : int.tryParse('FF$hex', radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

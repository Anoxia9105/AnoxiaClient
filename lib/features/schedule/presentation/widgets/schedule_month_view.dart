import 'package:anoxia/features/schedule/presentation/schedule_calendar_layout.dart';
import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ScheduleMonthView extends StatelessWidget {
  final DateTime focusedDay;
  final List<ScheduleOccurrence> occurrences;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<ScheduleEvent> onEventTap;

  const ScheduleMonthView({
    super.key,
    required this.focusedDay,
    required this.occurrences,
    required this.onDayTap,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final days = scheduleMonthGridDays(focusedDay);
    final locale = context.locale.toString();
    final monday = DateTime(2024, 1, 1);
    return Column(
      key: const ValueKey('schedule-month-view'),
      children: [
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: List.generate(7, (index) {
              final date = monday.add(Duration(days: index));
              return Expanded(
                child: Center(
                  child: Text(
                    DateFormat.E(locale).format(date),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / 7;
              final cellHeight = constraints.maxHeight / 6;
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: cellWidth / cellHeight,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) => _MonthDayCell(
                  day: days[index],
                  currentMonth: focusedDay.month,
                  occurrences: occurrences
                      .where(
                        (occurrence) =>
                            scheduleOccurrenceIsOnDay(occurrence, days[index]),
                      )
                      .toList(growable: false),
                  onDayTap: onDayTap,
                  onEventTap: onEventTap,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  final DateTime day;
  final int currentMonth;
  final List<ScheduleOccurrence> occurrences;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<ScheduleEvent> onEventTap;

  const _MonthDayCell({
    required this.day,
    required this.currentMonth,
    required this.occurrences,
    required this.onDayTap,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isToday =
        now.year == day.year && now.month == day.month && now.day == day.day;
    return InkWell(
      key: ValueKey('schedule-month-day-${day.toIso8601String()}'),
      onTap: () => onDayTap(day),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 4),
        decoration: BoxDecoration(
          color: day.month == currentMonth
              ? colors.surface
              : colors.surfaceContainerLowest,
          border: Border(
            right: BorderSide(color: colors.outlineVariant),
            bottom: BorderSide(color: colors.outlineVariant),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 27,
              height: 27,
              alignment: Alignment.center,
              decoration: isToday
                  ? BoxDecoration(color: colors.primary, shape: BoxShape.circle)
                  : null,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday
                      ? colors.onPrimary
                      : day.month == currentMonth
                      ? colors.onSurface
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 3),
            ...occurrences
                .take(3)
                .map(
                  (occurrence) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _MonthEvent(
                      occurrence: occurrence,
                      onTap: () => onEventTap(occurrence.event),
                    ),
                  ),
                ),
            if (occurrences.length > 3)
              Text(
                'schedule_more'.tr(args: ['${occurrences.length - 3}']),
                style: TextStyle(fontSize: 10, color: colors.primary),
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
    final locale = context.locale.toString();
    final prefix = occurrence.event.allDay
        ? ''
        : '${DateFormat.Hm(locale).format(start)} ';
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
              style: TextStyle(fontSize: 10, color: color),
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

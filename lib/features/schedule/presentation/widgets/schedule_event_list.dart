import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ScheduleAgenda extends StatelessWidget {
  final List<ScheduleEvent> events;
  final ValueChanged<ScheduleEvent> onEventTap;

  const ScheduleAgenda({
    super.key,
    required this.events,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const _EmptySchedule();
    final sorted = [...events]..sort((a, b) => a.startAt.compareTo(b.startAt));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) => ScheduleEventTile(
        event: sorted[index],
        showDate: true,
        onTap: () => onEventTap(sorted[index]),
      ),
    );
  }
}

class ScheduleQuickPanel extends StatelessWidget {
  final List<ScheduleEvent> events;
  final ValueChanged<ScheduleEvent> onEventTap;

  const ScheduleQuickPanel({
    super.key,
    required this.events,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = now.add(const Duration(days: 7));
    final todaysEvents = events.where((event) {
      final start = event.displayStartAt;
      final end = event.displayEndAt;
      return end.isAfter(today) && start.isBefore(tomorrow);
    }).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));
    final upcoming = events.where((event) {
      final start = event.displayStartAt;
      return start.isAfter(now) && start.isBefore(nextWeek);
    }).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(title: 'schedule_today_events'.tr()),
          const SizedBox(height: 8),
          if (todaysEvents.isEmpty)
            Text(
              'schedule_empty'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...todaysEvents
                .take(4)
                .map(
                  (event) => ScheduleEventTile(
                    event: event,
                    compact: true,
                    onTap: () => onEventTap(event),
                  ),
                ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'schedule_upcoming'.tr()),
          const SizedBox(height: 8),
          if (upcoming.isEmpty)
            Text(
              'schedule_no_upcoming'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...upcoming
                .take(8)
                .map(
                  (event) => ScheduleEventTile(
                    event: event,
                    compact: true,
                    showDate: true,
                    onTap: () => onEventTap(event),
                  ),
                ),
        ],
      ),
    );
  }
}

class ScheduleEventTile extends StatelessWidget {
  final ScheduleEvent event;
  final VoidCallback onTap;
  final bool compact;
  final bool showDate;

  const ScheduleEventTile({
    super.key,
    required this.event,
    required this.onTap,
    this.compact = false,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final start = event.displayStartAt;
    final end = event.displayEndAt;
    final color = _parseColor(
      event.color,
      Theme.of(context).colorScheme.primary,
    );
    final datePrefix = showDate
        ? '${DateFormat.MMMd(locale).format(start)} · '
        : '';
    final time = event.allDay
        ? 'schedule_all_day_label'.tr()
        : '${DateFormat.Hm(locale).format(start)}–${DateFormat.Hm(locale).format(end)}';
    return Material(
      color: compact
          ? Colors.transparent
          : Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 4 : 12,
            vertical: compact ? 7 : 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: compact ? 34 : 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$datePrefix$time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (!compact && event.location != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        event.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? value, Color fallback) {
    final hex = value?.replaceFirst('#', '');
    final parsed = hex == null ? null : int.tryParse('FF$hex', radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'schedule_empty'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'schedule_empty_hint'.tr(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

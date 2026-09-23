import 'dart:math' as math;

import 'package:anoxia/features/schedule/presentation/schedule_calendar_layout.dart';
import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

typedef ScheduleOccurrenceChanged =
    Future<void> Function(
      ScheduleOccurrence occurrence,
      DateTime start,
      DateTime end,
    );

class ScheduleTimelineView extends StatefulWidget {
  final DateTime focusedDay;
  final bool week;
  final List<ScheduleOccurrence> occurrences;
  final ValueChanged<DateTime> onEmptySlotTap;
  final ValueChanged<ScheduleEvent> onEventTap;
  final ScheduleOccurrenceChanged onOccurrenceChanged;

  const ScheduleTimelineView({
    super.key,
    required this.focusedDay,
    required this.week,
    required this.occurrences,
    required this.onEmptySlotTap,
    required this.onEventTap,
    required this.onOccurrenceChanged,
  });

  @override
  State<ScheduleTimelineView> createState() => _ScheduleTimelineViewState();
}

class _ScheduleTimelineViewState extends State<ScheduleTimelineView> {
  static const _hourHeight = 64.0;
  static const _gutterWidth = 72.0;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final hour = math.max(0, DateTime.now().hour - 2);
        _scrollController.jumpTo(hour * _hourHeight);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = scheduleTimelineDays(widget.focusedDay, week: widget.week);
    final allDay = widget.occurrences
        .where((occurrence) => occurrence.event.allDay)
        .toList(growable: false);
    return Column(
      key: ValueKey(widget.week ? 'schedule-week-view' : 'schedule-day-view'),
      children: [
        _TimelineHeader(days: days, gutterWidth: _gutterWidth),
        if (allDay.isNotEmpty)
          _AllDayStrip(
            days: days,
            occurrences: allDay,
            gutterWidth: _gutterWidth,
            onEventTap: widget.onEventTap,
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                width: constraints.maxWidth,
                height: 24 * _hourHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _TimeGutter(
                      width: _gutterWidth,
                      hourHeight: _hourHeight,
                    ),
                    ...days.map(
                      (day) => Expanded(
                        child: _TimelineDay(
                          day: day,
                          hourHeight: _hourHeight,
                          occurrences: widget.occurrences
                              .where(
                                (occurrence) =>
                                    !occurrence.event.allDay &&
                                    scheduleOccurrenceIsOnDay(occurrence, day),
                              )
                              .toList(growable: false),
                          onEmptySlotTap: widget.onEmptySlotTap,
                          onEventTap: widget.onEventTap,
                          onOccurrenceChanged: widget.onOccurrenceChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineHeader extends StatelessWidget {
  final List<DateTime> days;
  final double gutterWidth;

  const _TimelineHeader({required this.days, required this.gutterWidth});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locale = context.locale.toString();
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          SizedBox(width: gutterWidth),
          ...days.map((day) {
            final now = DateTime.now();
            final today =
                now.year == day.year &&
                now.month == day.month &&
                now.day == day.day;
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E(locale).format(day),
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat.MMMd(locale).format(day),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: today ? colors.primary : colors.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AllDayStrip extends StatelessWidget {
  final List<DateTime> days;
  final List<ScheduleOccurrence> occurrences;
  final double gutterWidth;
  final ValueChanged<ScheduleEvent> onEventTap;

  const _AllDayStrip({
    required this.days,
    required this.occurrences,
    required this.gutterWidth,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 38, maxHeight: 82),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: gutterWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 9, 8, 0),
              child: Text(
                'schedule_all_day_label'.tr(),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              ),
            ),
          ),
          ...days.map(
            (day) => Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Column(
                  children: occurrences
                      .where((item) => scheduleOccurrenceIsOnDay(item, day))
                      .take(2)
                      .map(
                        (item) => _CompactEvent(
                          occurrence: item,
                          onTap: () => onEventTap(item.event),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeGutter extends StatelessWidget {
  final double width;
  final double hourHeight;

  const _TimeGutter({required this.width, required this.hourHeight});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locale = context.locale.toString();
    return Container(
      width: width,
      color: colors.surfaceContainerLow,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(24, (hour) {
          final value = DateTime(2024, 1, 1, hour);
          return Positioned(
            top: hour * hourHeight + 4,
            right: 10,
            child: Text(
              DateFormat.Hm(locale).format(value),
              style: TextStyle(
                fontSize: 11,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: colors.onSurfaceVariant,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TimelineDay extends StatelessWidget {
  final DateTime day;
  final double hourHeight;
  final List<ScheduleOccurrence> occurrences;
  final ValueChanged<DateTime> onEmptySlotTap;
  final ValueChanged<ScheduleEvent> onEventTap;
  final ScheduleOccurrenceChanged onOccurrenceChanged;

  const _TimelineDay({
    required this.day,
    required this.hourHeight,
    required this.occurrences,
    required this.onEmptySlotTap,
    required this.onEventTap,
    required this.onOccurrenceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DragTarget<ScheduleOccurrence>(
      onAcceptWithDetails: (details) {
        final box = context.findRenderObject()! as RenderBox;
        final local = box.globalToLocal(details.offset);
        final minutes = snapScheduleMinutes(
          local.dy / hourHeight * 60,
        ).clamp(0, 24 * 60 - scheduleMinutesPerStep);
        final start = DateTime(
          day.year,
          day.month,
          day.day,
        ).add(Duration(minutes: minutes));
        final duration = details.data.endAt.difference(details.data.startAt);
        onOccurrenceChanged(details.data, start, start.add(duration));
      },
      builder: (context, candidates, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTapDown: (details) {
          final minutes = snapScheduleMinutes(
            details.localPosition.dy / hourHeight * 60,
          ).clamp(0, 24 * 60 - scheduleMinutesPerStep);
          onEmptySlotTap(
            DateTime(
              day.year,
              day.month,
              day.day,
            ).add(Duration(minutes: minutes)),
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: candidates.isEmpty
                ? colors.surface
                : colors.primaryContainer.withValues(alpha: 0.35),
            border: Border(left: BorderSide(color: colors.outlineVariant)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layouts = layoutScheduleOccurrences(occurrences);
              return Stack(
                children: [
                  ...List.generate(48, (index) {
                    final major = index.isEven;
                    return Positioned(
                      top: index * hourHeight / 2,
                      left: 0,
                      right: 0,
                      child: Divider(
                        height: 1,
                        thickness: major ? 1 : 0.5,
                        color: major
                            ? colors.outlineVariant
                            : colors.outlineVariant.withValues(alpha: 0.45),
                      ),
                    );
                  }),
                  ...layouts.map((layout) {
                    final occurrence = layout.occurrence;
                    final start = scheduleOccurrenceDisplayStart(occurrence);
                    final end = scheduleOccurrenceDisplayEnd(occurrence);
                    final dayStart = DateTime(day.year, day.month, day.day);
                    final startMinutes = math.max(
                      0,
                      start.difference(dayStart).inMinutes,
                    );
                    final endMinutes = math.min(
                      24 * 60,
                      end.difference(dayStart).inMinutes,
                    );
                    final height = math.max(
                      24.0,
                      (endMinutes - startMinutes) / 60 * hourHeight,
                    );
                    final columnWidth =
                        (constraints.maxWidth - 8) / layout.columnCount;
                    return Positioned(
                      top: startMinutes / 60 * hourHeight + 1,
                      left: 4 + columnWidth * layout.column,
                      width: math.max(16, columnWidth - 3),
                      height: height - 2,
                      child: _TimelineEvent(
                        occurrence: occurrence,
                        hourHeight: hourHeight,
                        onTap: () => onEventTap(occurrence.event),
                        onResize: (newEnd) =>
                            onOccurrenceChanged(occurrence, start, newEnd),
                      ),
                    );
                  }),
                  if (_isToday(day)) _NowLine(hourHeight: hourHeight),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime value) {
    final now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }
}

class _TimelineEvent extends StatefulWidget {
  final ScheduleOccurrence occurrence;
  final double hourHeight;
  final VoidCallback onTap;
  final ValueChanged<DateTime> onResize;

  const _TimelineEvent({
    required this.occurrence,
    required this.hourHeight,
    required this.onTap,
    required this.onResize,
  });

  @override
  State<_TimelineEvent> createState() => _TimelineEventState();
}

class _TimelineEventState extends State<_TimelineEvent> {
  double _resizeDelta = 0;

  @override
  Widget build(BuildContext context) {
    final event = widget.occurrence.event;
    final movable = event.recurrence == null && !event.allDay;
    final color = _eventColor(
      event.color,
      Theme.of(context).colorScheme.primary,
    );
    final start = scheduleOccurrenceDisplayStart(widget.occurrence);
    final end = scheduleOccurrenceDisplayEnd(widget.occurrence);
    final locale = context.locale.toString();
    final card = Material(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 5, 5, 3),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                '${DateFormat.Hm(locale).format(start)}–${DateFormat.Hm(locale).format(end)}',
                maxLines: 1,
                style: TextStyle(fontSize: 10, color: color),
              ),
              const Spacer(),
              if (movable)
                GestureDetector(
                  key: ValueKey('schedule-resize-${event.id}'),
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) =>
                      _resizeDelta += details.delta.dy,
                  onVerticalDragEnd: (_) {
                    final deltaMinutes = snapScheduleMinutes(
                      _resizeDelta / widget.hourHeight * 60,
                    );
                    _resizeDelta = 0;
                    final candidate = end.add(Duration(minutes: deltaMinutes));
                    final minimum = start.add(
                      const Duration(minutes: scheduleMinutesPerStep),
                    );
                    widget.onResize(
                      candidate.isBefore(minimum) ? minimum : candidate,
                    );
                  },
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 28,
                      height: 5,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (!movable) return card;
    return LongPressDraggable<ScheduleOccurrence>(
      data: widget.occurrence,
      feedback: SizedBox(width: 180, height: 64, child: card),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}

class _CompactEvent extends StatelessWidget {
  final ScheduleOccurrence occurrence;
  final VoidCallback onTap;

  const _CompactEvent({required this.occurrence, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(
      occurrence.event.color,
      Theme.of(context).colorScheme.primary,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: Text(
              occurrence.event.title,
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

class _NowLine extends StatelessWidget {
  final double hourHeight;

  const _NowLine({required this.hourHeight});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final top = (now.hour * 60 + now.minute) / 60 * hourHeight;
    final color = Theme.of(context).colorScheme.error;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(child: Divider(height: 1, thickness: 1.5, color: color)),
        ],
      ),
    );
  }
}

Color _eventColor(String? value, Color fallback) {
  final hex = value?.replaceFirst('#', '');
  final parsed = hex == null ? null : int.tryParse('FF$hex', radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

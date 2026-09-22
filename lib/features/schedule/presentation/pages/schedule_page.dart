import 'package:anoxia/features/schedule/presentation/widgets/schedule_event_dialog.dart';
import 'package:anoxia/features/schedule/presentation/widgets/schedule_event_list.dart';
import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:anoxia/framework/provider/schedule/schedule_service.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  final EventController<ScheduleEvent> _calendarController = EventController();
  ScheduleViewMode _view = ScheduleViewMode.month;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scheduleServiceProvider, (_, next) {
      next.whenData(_syncCalendarController);
    });
    final schedule = ref.watch(scheduleServiceProvider);
    final events = schedule.value ?? const <ScheduleEvent>[];
    final viewEvents = scheduleEventsOverlapping(
      events,
      scheduleRangeFor(_view, _focusedDay),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showQuickPanel = width >= 1120;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              _ScheduleToolbar(
                view: _view,
                focusedDay: _focusedDay,
                compact: width < 900,
                onViewChanged: _changeView,
                onToday: _showToday,
                onPrevious: () => _moveFocus(-1),
                onNext: () => _moveFocus(1),
                onCreate: () => _openEditor(initialStart: _focusedDay),
              ),
              const Divider(height: 1),
              Expanded(
                child: schedule.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, _) => _LoadError(onRetry: _load),
                  data: (_) => Row(
                    children: [
                      if (showQuickPanel) ...[
                        SizedBox(
                          width: 270,
                          child: ScheduleQuickPanel(
                            events: events,
                            onEventTap: _openExisting,
                          ),
                        ),
                        const VerticalDivider(width: 1),
                      ],
                      Expanded(child: _buildCalendar(viewEvents)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendar(List<ScheduleEvent> events) {
    final key = ValueKey('${_view.name}-${_focusedDay.toIso8601String()}');
    switch (_view) {
      case ScheduleViewMode.day:
        return DayView<ScheduleEvent>(
          key: key,
          controller: _calendarController,
          initialDay: _focusedDay,
          heightPerMinute: 0.8,
          startDuration: const Duration(hours: 7),
          showHalfHours: true,
          showLiveTimeLineInAllDays: true,
          onPageChange: (date, _) => _onCalendarPageChanged(date),
          onTimestampTap: (date) => _openEditor(initialStart: date),
          onEventTap: (items, _) {
            if (items.isNotEmpty) _openExisting(items.first.event!);
          },
        );
      case ScheduleViewMode.week:
        return WeekView<ScheduleEvent>(
          key: key,
          controller: _calendarController,
          initialDay: _focusedDay,
          heightPerMinute: 0.8,
          showHalfHours: true,
          showLiveTimeLineInAllDays: true,
          onPageChange: (date, _) => _onCalendarPageChanged(date),
          onTimestampTap: (date) => _openEditor(initialStart: date),
          onEventTap: (items, _) {
            if (items.isNotEmpty) _openExisting(items.first.event!);
          },
        );
      case ScheduleViewMode.month:
        return MonthView<ScheduleEvent>(
          key: key,
          controller: _calendarController,
          monthViewStyle: MonthViewStyle(
            startDay: WeekDays.monday,
            initialMonth: _focusedDay,
            useAvailableVerticalSpace: true,
          ),
          monthViewBuilders: MonthViewBuilders<ScheduleEvent>(
            onPageChange: (date, _) => _onCalendarPageChanged(date),
            onCellTap: (_, date) => _openEditor(initialStart: date),
            onEventTap: (item, _) => _openExisting(item.event!),
          ),
        );
      case ScheduleViewMode.agenda:
        return ScheduleAgenda(events: events, onEventTap: _openExisting);
    }
  }

  void _syncCalendarController(List<ScheduleEvent> events) {
    _calendarController.clear();
    _calendarController.addAll(
      events.expand(_toCalendarEntries).toList(growable: false),
    );
  }

  Iterable<CalendarEventData<ScheduleEvent>> _toCalendarEntries(
    ScheduleEvent event,
  ) sync* {
    final start = event.displayStartAt;
    final end = event.displayEndAt;
    final color = _eventColor(event);
    if (event.allDay) {
      yield CalendarEventData(
        title: event.title,
        description: event.description,
        date: start,
        endDate: end.subtract(const Duration(microseconds: 1)),
        color: color,
        event: event,
      );
      return;
    }
    DateTime day = DateTime(start.year, start.month, start.day);
    final lastDay = DateTime(end.year, end.month, end.day);
    while (!day.isAfter(lastDay)) {
      final isFirst =
          day.year == start.year &&
          day.month == start.month &&
          day.day == start.day;
      final isLast =
          day.year == end.year && day.month == end.month && day.day == end.day;
      if (isLast && end.hour == 0 && end.minute == 0 && !isFirst) break;
      final segmentStart = isFirst
          ? start
          : DateTime(day.year, day.month, day.day, 0, 1);
      final segmentEnd = isLast
          ? end
          : DateTime(day.year, day.month, day.day, 23, 59);
      yield CalendarEventData(
        title: event.title,
        description: event.description,
        date: day,
        startTime: segmentStart,
        endTime: segmentEnd,
        color: color,
        event: event,
      );
      day = day.add(const Duration(days: 1));
    }
  }

  Color _eventColor(ScheduleEvent event) {
    final hex = event.color?.replaceFirst('#', '');
    final value = hex == null ? null : int.tryParse('FF$hex', radix: 16);
    return value == null ? Theme.of(context).colorScheme.primary : Color(value);
  }

  Future<void> _load() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return ref
        .read(scheduleServiceProvider.notifier)
        .load(
          scheduleRangeFor(_view, _focusedDay),
          supplement: ScheduleRange(
            from: today,
            to: today.add(const Duration(days: 8)),
          ),
        );
  }

  void _changeView(ScheduleViewMode view) {
    setState(() => _view = view);
    _load();
  }

  void _showToday() {
    setState(() => _focusedDay = DateTime.now());
    _load();
  }

  void _moveFocus(int direction) {
    final next = switch (_view) {
      ScheduleViewMode.day => _focusedDay.add(Duration(days: direction)),
      ScheduleViewMode.week => _focusedDay.add(Duration(days: 7 * direction)),
      ScheduleViewMode.month => DateTime(
        _focusedDay.year,
        _focusedDay.month + direction,
        1,
      ),
      ScheduleViewMode.agenda => _focusedDay.add(
        Duration(days: 30 * direction),
      ),
    };
    setState(() => _focusedDay = next);
    _load();
  }

  void _onCalendarPageChanged(DateTime date) {
    if (!mounted) return;
    setState(() => _focusedDay = date);
    _load();
  }

  Future<void> _openEditor({DateTime? initialStart}) {
    return showScheduleEventDialog(
      context,
      initialStart: initialStart,
      onSave: (draft) =>
          ref.read(scheduleServiceProvider.notifier).create(draft),
    );
  }

  Future<void> _openExisting(ScheduleEvent event) {
    return showScheduleEventDialog(
      context,
      event: event,
      onSave: (draft) => ref
          .read(scheduleServiceProvider.notifier)
          .updateEvent(event.id, draft),
      onDelete: () =>
          ref.read(scheduleServiceProvider.notifier).deleteEvent(event.id),
    );
  }
}

class _ScheduleToolbar extends StatelessWidget {
  final ScheduleViewMode view;
  final DateTime focusedDay;
  final bool compact;
  final ValueChanged<ScheduleViewMode> onViewChanged;
  final VoidCallback onToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCreate;

  const _ScheduleToolbar({
    required this.view,
    required this.focusedDay,
    required this.compact,
    required this.onViewChanged,
    required this.onToday,
    required this.onPrevious,
    required this.onNext,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final title = DateFormat.yMMMM(locale).format(focusedDay);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (!compact)
            Text(
              'schedule_title'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          if (!compact) const SizedBox(width: 20),
          OutlinedButton(
            onPressed: onToday,
            child: Text('schedule_today'.tr()),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
          if (!compact)
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          if (compact)
            DropdownButton<ScheduleViewMode>(
              value: view,
              underline: const SizedBox.shrink(),
              items: ScheduleViewMode.values
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(_viewLabel(item)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onViewChanged(value);
              },
            )
          else
            SegmentedButton<ScheduleViewMode>(
              segments: ScheduleViewMode.values
                  .map(
                    (item) => ButtonSegment(
                      value: item,
                      label: Text(_viewLabel(item)),
                    ),
                  )
                  .toList(),
              selected: {view},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => onViewChanged(selection.first),
            ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: compact
                ? const SizedBox.shrink()
                : Text('schedule_new'.tr()),
          ),
        ],
      ),
    );
  }

  String _viewLabel(ScheduleViewMode value) => switch (value) {
    ScheduleViewMode.day => 'schedule_view_day'.tr(),
    ScheduleViewMode.week => 'schedule_view_week'.tr(),
    ScheduleViewMode.month => 'schedule_view_month'.tr(),
    ScheduleViewMode.agenda => 'schedule_view_agenda'.tr(),
  };
}

class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 12),
          Text('schedule_load_error'.tr()),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onRetry,
            child: Text('schedule_retry'.tr()),
          ),
        ],
      ),
    );
  }
}

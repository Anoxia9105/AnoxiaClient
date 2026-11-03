import 'package:anoxia/framework/provider/layout/desktop_layout_controller.dart';
import 'package:anoxia/framework/theme/composer_frame.dart';
import 'dart:async';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/features/schedule/presentation/schedule_calendar_layout.dart';
import 'package:anoxia/features/schedule/presentation/widgets/schedule_event_dialog.dart';
import 'package:anoxia/features/schedule/presentation/widgets/schedule_event_list.dart';
import 'package:anoxia/features/schedule/presentation/widgets/schedule_month_view.dart';
import 'package:anoxia/features/schedule/presentation/widgets/schedule_calendar_options.dart';
import 'package:anoxia/framework/domain/schedule_holiday.dart';
import 'package:anoxia/framework/provider/schedule/schedule_holidays.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anoxia/features/schedule/presentation/widgets/schedule_timeline_view.dart';
import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:anoxia/framework/core/notification_helper.dart';
import 'package:anoxia/framework/provider/schedule/schedule_service.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  ScheduleViewMode _view = ScheduleViewMode.month;
  DateTime _focusedDay = DateTime.now();
  ScheduleHolidayRegion _holidayRegion = ScheduleHolidayRegion.none;
  bool _showLunar = false;
  bool _preferencesStarted = false;
  final Map<String, Timer> _reminderTimers = {};

  /// 平板快捷面板（近期日程）是否以叠加 Sheet 打开。
  ///
  /// 面板常驻要求内容宽 ≥1120，平板横屏达不到，默认收起、点 FAB 按需弹出；
  /// 桌面/手机分支不受影响（桌面常驻、手机无入口）。
  bool _quickSheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_preferencesStarted) {
      _preferencesStarted = true;
      unawaited(_restoreCalendarPreferences(context.locale.languageCode));
    }
  }

  Future<void> _restoreCalendarPreferences(String language) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('schedule.holidayRegion');
    final region =
        ScheduleHolidayRegion.values
            .where((r) => r.name == saved)
            .firstOrNull ??
        switch (language) {
          'zh' => ScheduleHolidayRegion.cn,
          'ja' => ScheduleHolidayRegion.jp,
          _ => ScheduleHolidayRegion.none,
        };
    final lunar =
        prefs.getBool('schedule.showLunar') ??
        region == ScheduleHolidayRegion.cn;
    if (!mounted) return;
    setState(() {
      _holidayRegion = region;
      _showLunar = lunar;
    });
    await prefs.setString('schedule.holidayRegion', region.name);
    await prefs.setBool('schedule.showLunar', lunar);
  }

  Future<void> _saveCalendarPreferences({
    ScheduleHolidayRegion? region,
    bool? lunar,
  }) async {
    setState(() {
      _holidayRegion = region ?? _holidayRegion;
      _showLunar = lunar ?? _showLunar;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('schedule.holidayRegion', _holidayRegion.name);
    await prefs.setBool('schedule.showLunar', _showLunar);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scheduleServiceProvider, (_, next) {
      next.whenData(_scheduleReminders);
    });
    final schedule = ref.watch(scheduleServiceProvider);
    final events = schedule.value ?? const <ScheduleEvent>[];
    final range = scheduleRangeFor(_view, _focusedDay);
    final viewOccurrences = expandScheduleOccurrences(events, range);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final quickOccurrences = expandScheduleOccurrences(
      events,
      ScheduleRange(from: today, to: today.add(const Duration(days: 8))),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = DeviceUtil.isMobile(context);
        final singleColumn = DeviceUtil.useSingleColumnPush(context);
        final showQuickPanel = width >= 720 && !singleColumn;
        final showQuickSheet = !isMobile && !showQuickPanel && _quickSheetOpen;
        final colors = Theme.of(context).colorScheme;
        final style = DeviceUtil.supportsDesktopLayoutPreference(context)
            ? resolveDesktopLayoutStyle(
                ref.watch(desktopLayoutProvider),
                availableWidth: MediaQuery.sizeOf(context).width,
              )
            : DesktopLayoutStyle.card;
        final card = showQuickPanel && style == DesktopLayoutStyle.card;
        final calendar = Column(
          children: [
            _ScheduleToolbar(
              view: _view,
              focusedDay: _focusedDay,
              compact: width - (showQuickPanel ? 300 : 0) < 840,
              calendarOptions: ScheduleCalendarOptions(
                region: _holidayRegion,
                showLunar: _showLunar,
                onRegionChanged: (value) =>
                    _saveCalendarPreferences(region: value),
                onLunarChanged: (value) =>
                    _saveCalendarPreferences(lunar: value),
              ),
              onViewChanged: _changeView,
              onToday: _showToday,
              onPrevious: () => _moveFocus(-1),
              onNext: () => _moveFocus(1),
              onCreate: () => _openEditor(initialStart: _focusedDay),
            ),
            Divider(height: 1, color: ComposerFrame.side(colors).color),
            Expanded(
              child: schedule.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _LoadError(onRetry: _load),
                data: (_) => _buildCalendar(viewOccurrences),
              ),
            ),
          ],
        );
        return Scaffold(
          backgroundColor: singleColumn
              ? colors.surfaceContainerLowest
              : Theme.of(context).scaffoldBackgroundColor,
          appBar: isMobile
              ? AppBar(
                  key: const ValueKey('schedule-mobile-app-bar'),
                  centerTitle: true,
                  titleSpacing: 16,
                  title: Text('schedule_title'.tr()),
                  backgroundColor: colors.surfaceContainerLowest,
                  surfaceTintColor: Colors.transparent,
                )
              : null,
          body: SafeArea(
            key: const ValueKey('schedule-body-safe-area'),
            top: !isMobile,
            child: Stack(
              children: [
                Row(
                  children: [
                    if (showQuickPanel) ...[
                      SizedBox(
                        key: const ValueKey('schedule-left-list'),
                        width: 280,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'schedule_title'.tr(),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Expanded(
                              child: ScheduleQuickPanel(
                                occurrences: quickOccurrences,
                                onEventTap: _openExisting,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!card) const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: card
                          ? Container(
                              key: const ValueKey('schedule-calendar-card'),
                              margin: const EdgeInsets.fromLTRB(8, 12, 12, 12),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: ComposerFrame.radius,
                                border: Border.fromBorderSide(
                                  ComposerFrame.side(colors),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.shadow.withValues(alpha: .10),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                // 内容沿描边内缘裁剪，避免日期网格覆盖圆角。
                                borderRadius: BorderRadius.circular(
                                  RadiusToken.lg -
                                      ComposerFrame.side(colors).width,
                                ),
                                child: calendar,
                              ),
                            )
                          : calendar,
                    ),
                  ],
                ),
                if (showQuickSheet)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _quickSheetOpen = false),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 270,
                            margin: const EdgeInsets.fromLTRB(8, 10, 12, 12),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerLowest,
                              borderRadius: ComposerFrame.radius,
                              border: Border.fromBorderSide(
                                ComposerFrame.side(colors),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.shadow.withValues(alpha: .08),
                                  blurRadius: 24,
                                  offset: const Offset(-8, 8),
                                ),
                              ],
                            ),
                            child: ScheduleQuickPanel(
                              occurrences: quickOccurrences,
                              onEventTap: (event) {
                                setState(() => _quickSheetOpen = false);
                                _openExisting(event);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: !isMobile && !showQuickPanel && !showQuickSheet
              ? FloatingActionButton.small(
                  tooltip: 'schedule_upcoming'.tr(),
                  onPressed: () => setState(() => _quickSheetOpen = true),
                  child: const Icon(Icons.upcoming_outlined),
                )
              : null,
        );
      },
    );
  }

  @override
  void dispose() {
    for (final timer in _reminderTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Widget _buildCalendar(List<ScheduleOccurrence> occurrences) {
    final key = ValueKey('${_view.name}-${_focusedDay.toIso8601String()}');
    switch (_view) {
      case ScheduleViewMode.day:
        return ScheduleTimelineView(
          key: key,
          focusedDay: _focusedDay,
          week: false,
          occurrences: occurrences,
          onEmptySlotTap: (date) => _openEditor(initialStart: date),
          onEventTap: _openExisting,
          onOccurrenceChanged: _rescheduleOccurrence,
        );
      case ScheduleViewMode.week:
        return ScheduleTimelineView(
          key: key,
          focusedDay: _focusedDay,
          week: true,
          occurrences: occurrences,
          onEmptySlotTap: (date) => _openEditor(initialStart: date),
          onEventTap: _openExisting,
          onOccurrenceChanged: _rescheduleOccurrence,
        );
      case ScheduleViewMode.month:
        return ScheduleMonthView(
          key: key,
          focusedDay: _focusedDay,
          occurrences: occurrences,
          holidays:
              ref
                  .watch(
                    scheduleHolidaysProvider(_holidayRegion, _focusedDay.year),
                  )
                  .value ??
              const {},
          showLunar: _showLunar,
          onDayTap: (date) => _openEditor(initialStart: date),
          onEventTap: _openExisting,
        );
      case ScheduleViewMode.agenda:
        return ScheduleAgenda(
          occurrences: occurrences,
          onEventTap: _openExisting,
        );
    }
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

  Future<void> _rescheduleOccurrence(
    ScheduleOccurrence occurrence,
    DateTime start,
    DateTime end,
  ) async {
    try {
      await ref
          .read(scheduleServiceProvider.notifier)
          .reschedule(occurrence.event, start, end);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('schedule_move_error'.tr())));
    }
  }

  void _scheduleReminders(List<ScheduleEvent> events) {
    for (final timer in _reminderTimers.values) {
      timer.cancel();
    }
    _reminderTimers.clear();
    final now = DateTime.now();
    final occurrences = expandScheduleOccurrences(
      events.where((event) => event.reminderMinutes != null),
      ScheduleRange(from: now, to: now.add(const Duration(days: 31))),
    );
    for (final occurrence in occurrences) {
      final triggerAt = scheduleReminderTriggerAt(occurrence);
      if (triggerAt == null) continue;
      if (!triggerAt.isAfter(now)) continue;
      final key =
          '${occurrence.event.id}:${occurrence.occurrenceIndex}:'
          '${occurrence.startAt.millisecondsSinceEpoch}';
      _reminderTimers[key] = Timer(triggerAt.difference(now), () {
        _reminderTimers.remove(key);
        final start = occurrence.startAt.toLocal();
        unawaited(
          NotificationHelper().show(
            id: 0x3fffffff & key.hashCode,
            title: occurrence.event.title,
            body: 'schedule_reminder_body'.tr(
              args: [
                DateFormat.yMMMd(context.locale.toString()).format(start),
                DateFormat.Hm(context.locale.toString()).format(start),
              ],
            ),
            force: true,
          ),
        );
      });
    }
  }
}

class _ScheduleToolbar extends StatelessWidget {
  final Widget calendarOptions;
  final ScheduleViewMode view;
  final DateTime focusedDay;
  final bool compact;
  final ValueChanged<ScheduleViewMode> onViewChanged;
  final VoidCallback onToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCreate;

  const _ScheduleToolbar({
    required this.calendarOptions,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final navigation = <Widget>[
            if (compact)
              IconButton(
                tooltip: 'schedule_today'.tr(),
                onPressed: onToday,
                icon: const Icon(Icons.today_outlined),
              )
            else
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
            if (compact)
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
            else
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (!compact) const Spacer(),
          ];
          final actions = <Widget>[
            _ScheduleNotificationButton(locale: context.locale),
            calendarOptions,
            const SizedBox(width: 8),
            if (compact)
              PopupMenuButton<ScheduleViewMode>(
                tooltip: _viewLabel(view),
                initialValue: view,
                icon: const Icon(Icons.calendar_view_week_outlined),
                itemBuilder: (_) => ScheduleViewMode.values
                    .map(
                      (item) => PopupMenuItem(
                        value: item,
                        child: Text(_viewLabel(item)),
                      ),
                    )
                    .toList(),
                onSelected: onViewChanged,
              )
            else
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: SegmentedButton<ScheduleViewMode>(
                    style: SegmentedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RadiusToken.md),
                      ),
                    ),
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
                    onSelectionChanged: (selection) =>
                        onViewChanged(selection.first),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            if (compact)
              IconButton.filled(
                key: const ValueKey('schedule-create-button'),
                tooltip: 'schedule_new'.tr(),
                onPressed: onCreate,
                icon: const Icon(Icons.add, color: Colors.white),
              )
            else
              FilledButton.icon(
                key: const ValueKey('schedule-create-button'),
                onPressed: onCreate,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text('schedule_new'.tr()),
              ),
          ];
          if (compact && constraints.maxWidth < 500) {
            return Column(
              children: [
                Row(children: navigation),
                Row(children: [const Spacer(), ...actions]),
              ],
            );
          }
          return Row(children: [...navigation, ...actions]);
        },
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

class _ScheduleNotificationButton extends StatefulWidget {
  // Keep locale as an explicit input so this stateful child rebuilds when the
  // app language changes, even when its notification permission state does not.
  final Locale locale;

  const _ScheduleNotificationButton({required this.locale});

  @override
  State<_ScheduleNotificationButton> createState() =>
      _ScheduleNotificationButtonState();
}

class _ScheduleNotificationButtonState
    extends State<_ScheduleNotificationButton> {
  bool _granted = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _readPermission();
  }

  Future<void> _readPermission() async {
    final granted = await NotificationHelper().isPermissionGranted();
    if (mounted) {
      setState(() {
        _granted = granted;
        _checking = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    if (_checking) return;
    setState(() => _checking = true);
    final granted = await NotificationHelper().requestPermission();
    if (!mounted) return;
    setState(() {
      _granted = granted;
      _checking = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'schedule_notification_enabled'.tr()
              : 'schedule_notification_denied'.tr(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final helper = NotificationHelper();
    if (!helper.isSupported) return const SizedBox.shrink();
    return IconButton.filledTonal(
      key: const ValueKey('schedule-notification-button'),
      tooltip: _granted
          ? 'schedule_notification_enabled'.tr()
          : 'schedule_notification_enable'.tr(),
      onPressed: _granted || _checking ? null : _requestPermission,
      icon: _checking
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _granted
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none_rounded,
            ),
    );
  }
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

import 'package:anoxia/framework/domain/schedule_event.dart';
import 'package:anoxia/features/schedule/presentation/widgets/schedule_event_options.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<void> showScheduleEventDialog(
  BuildContext context, {
  ScheduleEvent? event,
  DateTime? initialStart,
  required Future<void> Function(ScheduleEventDraft draft) onSave,
  Future<void> Function()? onDelete,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ScheduleEventDialog(
      event: event,
      initialStart: initialStart,
      onSave: onSave,
      onDelete: onDelete,
    ),
  );
}

class _ScheduleEventDialog extends StatefulWidget {
  final ScheduleEvent? event;
  final DateTime? initialStart;
  final Future<void> Function(ScheduleEventDraft draft) onSave;
  final Future<void> Function()? onDelete;

  const _ScheduleEventDialog({
    required this.event,
    required this.initialStart,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_ScheduleEventDialog> createState() => _ScheduleEventDialogState();
}

class _ScheduleEventDialogState extends State<_ScheduleEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _colorController;
  late DateTime _start;
  late DateTime _end;
  late bool _allDay;
  late String _color;
  int? _reminderMinutes;
  ScheduleRecurrence? _recurrence;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final rounded = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute < 30 ? 30 : 0,
    ).add(now.minute < 30 ? Duration.zero : const Duration(hours: 1));
    _allDay = widget.event?.allDay ?? false;
    _start = widget.event?.displayStartAt ?? widget.initialStart ?? rounded;
    final storedEnd = widget.event?.displayEndAt;
    if (storedEnd == null) {
      _end = _start.add(const Duration(hours: 1));
    } else if (_allDay) {
      _end = storedEnd.subtract(const Duration(days: 1));
    } else {
      _end = storedEnd;
    }
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.event?.description ?? '',
    );
    _locationController = TextEditingController(
      text: widget.event?.location ?? '',
    );
    _color = (widget.event?.color ?? '#4F6BED').toUpperCase();
    _colorController = TextEditingController(text: _color);
    _reminderMinutes = widget.event?.reminderMinutes;
    _recurrence = widget.event?.recurrence;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final screen = MediaQuery.sizeOf(context);
    final isCompact = screen.width < 720;
    final width = isCompact
        ? screen.width
        : (screen.width - 48).clamp(680.0, 920.0);
    final height = isCompact
        ? (screen.height - 64).clamp(0.0, 820.0)
        : (screen.height - 48).clamp(0.0, 720.0);
    final inputTheme = Theme.of(context).inputDecorationTheme.copyWith(
      filled: true,
      fillColor: colors.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 1.6),
      ),
    );
    return Dialog(
      alignment: isCompact ? Alignment.bottomCenter : Alignment.center,
      insetPadding: isCompact
          ? const EdgeInsets.only(top: 64)
          : const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: isCompact
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(20),
      ),
      child: SizedBox(
        key: const ValueKey('schedule-event-dialog'),
        width: width,
        height: height,
        child: Column(
          children: [
            _buildHeader(context, isCompact),
            Expanded(
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(inputDecorationTheme: inputTheme),
                child: Form(
                  key: _formKey,
                  child: isCompact
                      ? SingleChildScrollView(
                          key: const ValueKey('schedule-dialog-mobile-content'),
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPrimaryColumn(context),
                              const SizedBox(height: 24),
                              Divider(color: colors.outlineVariant),
                              const SizedBox(height: 20),
                              _buildSettingsColumn(context),
                            ],
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                key: const ValueKey(
                                  'schedule-dialog-primary-column',
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  28,
                                  24,
                                  28,
                                  32,
                                ),
                                child: _buildPrimaryColumn(context),
                              ),
                            ),
                            VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: colors.outlineVariant,
                            ),
                            SizedBox(
                              key: const ValueKey(
                                'schedule-dialog-settings-column',
                              ),
                              width: 344,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  24,
                                  24,
                                  32,
                                ),
                                child: _buildSettingsColumn(context),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            Container(
              key: const ValueKey('schedule-dialog-footer'),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: Row(
                children: isCompact
                    ? [
                        if (widget.onDelete != null) ...[
                          IconButton(
                            tooltip: 'schedule_delete'.tr(),
                            onPressed: _saving ? null : _delete,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: colors.error,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: TextButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('schedule_cancel'.tr()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                            ),
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox.square(
                                    dimension: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('schedule_save'.tr()),
                                  ),
                          ),
                        ),
                      ]
                    : [
                        if (widget.onDelete != null)
                          TextButton.icon(
                            onPressed: _saving ? null : _delete,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: colors.error,
                            ),
                            label: Text(
                              'schedule_delete'.tr(),
                              style: TextStyle(color: colors.error),
                            ),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text('schedule_cancel'.tr()),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text('schedule_save'.tr()),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isCompact) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(isCompact ? 18 : 24, 12, 12, 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: isCompact ? 38 : 42,
            height: isCompact ? 38 : 42,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.event == null
                  ? Icons.event_available_outlined
                  : Icons.edit_calendar_outlined,
              color: colors.onPrimaryContainer,
              size: isCompact ? 21 : 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.event == null
                      ? 'schedule_new'.tr()
                      : 'schedule_edit'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 2),
                  Text(
                    'schedule_dialog_subtitle'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryColumn(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _titleController,
          autofocus: true,
          maxLength: 200,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: 'schedule_event_title'.tr(),
            counterText: '',
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'schedule_title_required'.tr()
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _locationController,
          maxLength: 255,
          decoration: InputDecoration(
            labelText: 'schedule_location'.tr(),
            prefixIcon: const Icon(Icons.location_on_outlined),
            counterText: '',
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 20, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'schedule_time_section'.tr(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 72),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        'schedule_all_day'.tr(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Switch(
                    key: const ValueKey('schedule-all-day'),
                    value: _allDay,
                    onChanged: _saving ? null : _setAllDay,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _DateTimeRow(
                label: 'schedule_start'.tr(),
                value: _start,
                allDay: _allDay,
                onDateTap: () => _pickDate(isStart: true),
                onTimeTap: () => _pickTime(isStart: true),
              ),
              const SizedBox(height: 10),
              _DateTimeRow(
                label: 'schedule_end'.tr(),
                value: _end,
                allDay: _allDay,
                onDateTap: () => _pickDate(isStart: false),
                onTimeTap: () => _pickTime(isStart: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        TextFormField(
          controller: _descriptionController,
          maxLength: 4000,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: 'schedule_description'.tr(),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 48),
              child: Icon(Icons.notes_rounded),
            ),
            alignLabelWithHint: true,
            counterText: '',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: TextStyle(color: colors.error)),
        ],
      ],
    );
  }

  Widget _buildSettingsColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'schedule_settings'.tr(),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        ScheduleReminderField(
          value: _reminderMinutes,
          enabled: !_saving,
          onChanged: (value) => setState(() => _reminderMinutes = value),
        ),
        const SizedBox(height: 12),
        ScheduleRecurrenceEditor(
          value: _recurrence,
          enabled: !_saving,
          onChanged: (value) => setState(() => _recurrence = value),
        ),
        const SizedBox(height: 22),
        ScheduleColorPicker(
          controller: _colorController,
          selectedColor: _color,
          enabled: !_saving,
          onChanged: (color) {
            setState(() {
              _color = color;
              _colorController.text = color;
            });
          },
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final updated = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
      );
      if (isStart) {
        final duration = _end.difference(_start);
        _start = updated;
        if (!_end.isAfter(_start)) _end = _start.add(duration);
      } else {
        _end = updated;
      }
    });
  }

  void _setAllDay(bool value) {
    setState(() {
      _allDay = value;
      if (!value && !_end.isAfter(_start)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final updated = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      );
      if (isStart) {
        _start = updated;
        if (!_end.isAfter(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = updated;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    DateTime start = _start;
    DateTime end = _end;
    if (_allDay) {
      start = DateTime.utc(_start.year, _start.month, _start.day);
      end = DateTime.utc(
        _end.year,
        _end.month,
        _end.day,
      ).add(const Duration(days: 1));
    }
    if (!end.isAfter(start)) {
      setState(() => _error = 'schedule_time_invalid'.tr());
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        ScheduleEventDraft(
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          startAt: start,
          endAt: end,
          allDay: _allDay,
          color: _colorController.text.trim().toUpperCase(),
          reminderMinutes: _reminderMinutes,
          recurrence: _recurrence,
          revision: widget.event?.revision,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'schedule_save_error'.tr();
        });
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text('schedule_delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('schedule_cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('schedule_delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.onDelete!();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'schedule_delete_error'.tr();
        });
      }
    }
  }
}

class _DateTimeRow extends StatelessWidget {
  final String label;
  final DateTime value;
  final bool allDay;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  const _DateTimeRow({
    required this.label,
    required this.value,
    required this.allDay,
    required this.onDateTap,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    return Row(
      children: [
        SizedBox(width: 62, child: Text(label)),
        Expanded(
          child: OutlinedButton(
            onPressed: onDateTap,
            child: Text(DateFormat.yMMMd(locale).format(value)),
          ),
        ),
        if (!allDay) ...[
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onTimeTap,
            child: Text(DateFormat.Hm(locale).format(value)),
          ),
        ],
      ],
    );
  }
}

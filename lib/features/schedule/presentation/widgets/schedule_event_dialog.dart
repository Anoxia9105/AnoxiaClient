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
    final width = (screen.width - 48).clamp(320.0, 680.0);
    final height = (screen.height - 48).clamp(420.0, 720.0);
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
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        key: const ValueKey('schedule-event-dialog'),
        width: width,
        height: height,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border(
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.event == null
                          ? Icons.event_available_outlined
                          : Icons.edit_calendar_outlined,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.event == null
                          ? 'schedule_new'.tr()
                          : 'schedule_edit'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(inputDecorationTheme: inputTheme),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          autofocus: true,
                          maxLength: 200,
                          decoration: InputDecoration(
                            labelText: 'schedule_event_title'.tr(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'schedule_title_required'.tr()
                              : null,
                        ),
                        TextFormField(
                          controller: _locationController,
                          maxLength: 255,
                          decoration: InputDecoration(
                            labelText: 'schedule_location'.tr(),
                          ),
                        ),
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
                        const SizedBox(height: 12),
                        ScheduleReminderField(
                          value: _reminderMinutes,
                          enabled: !_saving,
                          onChanged: (value) =>
                              setState(() => _reminderMinutes = value),
                        ),
                        const SizedBox(height: 12),
                        ScheduleRecurrenceEditor(
                          value: _recurrence,
                          enabled: !_saving,
                          onChanged: (value) =>
                              setState(() => _recurrence = value),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          key: const ValueKey('schedule-all-day'),
                          contentPadding: EdgeInsets.zero,
                          title: Text('schedule_all_day'.tr()),
                          value: _allDay,
                          onChanged: _saving ? null : _setAllDay,
                        ),
                        _DateTimeRow(
                          label: 'schedule_start'.tr(),
                          value: _start,
                          allDay: _allDay,
                          onDateTap: () => _pickDate(isStart: true),
                          onTimeTap: () => _pickTime(isStart: true),
                        ),
                        const SizedBox(height: 8),
                        _DateTimeRow(
                          label: 'schedule_end'.tr(),
                          value: _end,
                          allDay: _allDay,
                          onDateTap: () => _pickDate(isStart: false),
                          onTimeTap: () => _pickTime(isStart: false),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLength: 4000,
                          minLines: 2,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: 'schedule_description'.tr(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        if (_error != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: Row(
                children: [
                  if (widget.onDelete != null)
                    TextButton.icon(
                      onPressed: _saving ? null : _delete,
                      icon: Icon(Icons.delete_outline, color: colors.error),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
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

import 'package:anoxia/framework/domain/schedule_event.dart';
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
  late DateTime _start;
  late DateTime _end;
  late bool _allDay;
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.event == null ? 'schedule_new'.tr() : 'schedule_edit'.tr(),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: 'schedule_event_title'.tr(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
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
                SwitchListTile(
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
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: _saving ? null : _delete,
            child: Text(
              'schedule_delete'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text('schedule_cancel'.tr()),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('schedule_save'.tr()),
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

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../framework/domain/schedule_event.dart';

const scheduleEventColors = <String>[
  '#4F6BED',
  '#0F766E',
  '#15803D',
  '#B45309',
  '#D14343',
  '#7E22CE',
  '#475569',
];

class ScheduleSelectOption<T> {
  final T value;
  final String label;

  const ScheduleSelectOption({required this.value, required this.label});
}

class ScheduleSelectField<T> extends StatelessWidget {
  final T value;
  final List<ScheduleSelectOption<T>> options;
  final ValueChanged<T> onChanged;
  final String label;
  final IconData? icon;
  final bool enabled;

  const ScheduleSelectField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.label,
    required this.enabled,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = options.firstWhere((option) => option.value == value);
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.surfaceContainer),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 6),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      builder: (context, controller, child) => Semantics(
        button: true,
        enabled: enabled,
        label: label,
        value: selected.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled
              ? () => controller.isOpen ? controller.close() : controller.open()
              : null,
          child: InputDecorator(
            isEmpty: false,
            isFocused: controller.isOpen,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: icon == null ? null : Icon(icon),
              suffixIcon: AnimatedRotation(
                duration: const Duration(milliseconds: 160),
                turns: controller.isOpen ? 0.5 : 0,
                child: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              enabled: enabled,
            ),
            child: Text(
              selected.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      menuChildren: options
          .map(
            (option) => MenuItemButton(
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(Size(280, 46)),
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              leadingIcon: Icon(
                option.value == value ? Icons.check_rounded : null,
                color: option.value == value ? colors.primary : null,
              ),
              onPressed: enabled ? () => onChanged(option.value) : null,
              child: Text(
                option.label,
                style: TextStyle(
                  fontWeight: option.value == value
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: option.value == value ? colors.primary : null,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class ScheduleColorPicker extends StatelessWidget {
  final TextEditingController controller;
  final String selectedColor;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const ScheduleColorPicker({
    super.key,
    required this.controller,
    required this.selectedColor,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'schedule_color'.tr(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: scheduleEventColors
              .map((color) {
                final selected = color == selectedColor.toUpperCase();
                return Semantics(
                  button: true,
                  selected: selected,
                  label: 'schedule_color_option'.tr(args: [color]),
                  child: Tooltip(
                    message: color,
                    child: InkWell(
                      key: ValueKey('schedule-color-$color'),
                      customBorder: const CircleBorder(),
                      onTap: enabled ? () => onChanged(color) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _parseColor(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: const ValueKey('schedule-custom-color'),
          controller: controller,
          enabled: enabled,
          maxLength: 7,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'schedule_custom_color'.tr(),
            prefixIcon: const Icon(Icons.palette_outlined),
            counterText: '',
          ),
          validator: (value) {
            final normalized = value?.trim() ?? '';
            return RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(normalized)
                ? null
                : 'schedule_color_invalid'.tr();
          },
          onChanged: (value) {
            final normalized = value.trim().toUpperCase();
            if (RegExp(r'^#[0-9A-F]{6}$').hasMatch(normalized)) {
              onChanged(normalized);
            }
          },
        ),
      ],
    );
  }

  Color _parseColor(String value) {
    return Color(int.parse('FF${value.substring(1)}', radix: 16));
  }
}

class ScheduleReminderField extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final bool enabled;

  const ScheduleReminderField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  static const _options = <int>[-1, 0, 5, 10, 15, 30, 60, 1440];

  @override
  Widget build(BuildContext context) {
    return ScheduleSelectField<int>(
      key: const ValueKey('schedule-reminder'),
      value: value ?? -1,
      label: 'schedule_reminder'.tr(),
      icon: Icons.notifications_none_rounded,
      enabled: enabled,
      options: _options
          .map(
            (minutes) =>
                ScheduleSelectOption(value: minutes, label: _label(minutes)),
          )
          .toList(growable: false),
      onChanged: (minutes) => onChanged(minutes < 0 ? null : minutes),
    );
  }

  String _label(int minutes) => switch (minutes) {
    -1 => 'schedule_reminder_none'.tr(),
    0 => 'schedule_reminder_at_start'.tr(),
    5 => 'schedule_reminder_5'.tr(),
    10 => 'schedule_reminder_10'.tr(),
    15 => 'schedule_reminder_15'.tr(),
    30 => 'schedule_reminder_30'.tr(),
    60 => 'schedule_reminder_60'.tr(),
    1440 => 'schedule_reminder_1440'.tr(),
    _ => 'schedule_reminder_none'.tr(),
  };
}

class ScheduleRecurrenceEditor extends StatefulWidget {
  final ScheduleRecurrence? value;
  final ValueChanged<ScheduleRecurrence?> onChanged;
  final bool enabled;

  const ScheduleRecurrenceEditor({
    super.key,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  @override
  State<ScheduleRecurrenceEditor> createState() =>
      _ScheduleRecurrenceEditorState();
}

class _ScheduleRecurrenceEditorState extends State<ScheduleRecurrenceEditor> {
  late ScheduleRecurrenceFrequency? _frequency;
  late ScheduleRecurrenceEndType _endType;
  late Set<int> _weekdays;
  late DateTime _until;
  late final TextEditingController _intervalController;
  late final TextEditingController _countController;

  @override
  void initState() {
    super.initState();
    final recurrence = widget.value;
    _frequency = recurrence?.frequency;
    _endType = recurrence?.endType ?? ScheduleRecurrenceEndType.never;
    _weekdays = {...?recurrence?.weekdays};
    _until =
        recurrence?.until?.toLocal() ??
        DateTime.now().add(const Duration(days: 90));
    _intervalController = TextEditingController(
      text: (recurrence?.interval ?? 1).toString(),
    );
    _countController = TextEditingController(
      text: (recurrence?.count ?? 10).toString(),
    );
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('schedule-recurrence'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScheduleSelectField<ScheduleRecurrenceFrequency?>(
            key: const ValueKey('schedule-recurrence-frequency'),
            value: _frequency,
            label: 'schedule_repeat'.tr(),
            icon: Icons.repeat_rounded,
            enabled: widget.enabled,
            options: [
              ScheduleSelectOption<ScheduleRecurrenceFrequency?>(
                value: null,
                label: 'schedule_repeat_none'.tr(),
              ),
              ...ScheduleRecurrenceFrequency.values.map(
                (frequency) => ScheduleSelectOption(
                  value: frequency,
                  label: _frequencyLabel(frequency),
                ),
              ),
            ],
            onChanged: (frequency) {
              setState(() {
                _frequency = frequency;
                if (frequency == ScheduleRecurrenceFrequency.weekly &&
                    _weekdays.isEmpty) {
                  _weekdays.add(DateTime.now().weekday);
                }
              });
              _emit();
            },
          ),
          if (_frequency != null) ...[
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('schedule-recurrence-interval'),
              controller: _intervalController,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'schedule_repeat_interval'.tr(),
              ),
              validator: (value) {
                if (_frequency == null) return null;
                final interval = int.tryParse(value ?? '');
                return interval == null || interval < 1 || interval > 99
                    ? 'schedule_repeat_interval_invalid'.tr()
                    : null;
              },
              onChanged: (_) => _emit(),
            ),
            if (_frequency == ScheduleRecurrenceFrequency.weekly) ...[
              const SizedBox(height: 12),
              Text(
                'schedule_repeat_on'.tr(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              FormField<Set<int>>(
                initialValue: _weekdays,
                validator: (_) => _weekdays.isEmpty
                    ? 'schedule_repeat_weekday_required'.tr()
                    : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      children: List.generate(7, (index) {
                        final weekday = index + 1;
                        return FilterChip(
                          key: ValueKey('schedule-recurrence-weekday-$weekday'),
                          selected: _weekdays.contains(weekday),
                          label: Text(_weekdayLabel(context, weekday)),
                          onSelected: widget.enabled
                              ? (selected) {
                                  setState(() {
                                    if (selected) {
                                      _weekdays.add(weekday);
                                    } else {
                                      _weekdays.remove(weekday);
                                    }
                                  });
                                  field.didChange(_weekdays);
                                  _emit();
                                }
                              : null,
                        );
                      }),
                    ),
                    if (field.hasError) ...[
                      const SizedBox(height: 6),
                      Text(
                        field.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            ScheduleSelectField<ScheduleRecurrenceEndType>(
              key: const ValueKey('schedule-recurrence-end'),
              value: _endType,
              label: 'schedule_repeat_end'.tr(),
              enabled: widget.enabled,
              options: ScheduleRecurrenceEndType.values
                  .map(
                    (type) => ScheduleSelectOption(
                      value: type,
                      label: _endTypeLabel(type),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (type) {
                setState(() => _endType = type);
                _emit();
              },
            ),
            if (_endType == ScheduleRecurrenceEndType.until) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('schedule-recurrence-until'),
                onPressed: widget.enabled ? _pickUntil : null,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  DateFormat.yMMMd(context.locale.toString()).format(_until),
                ),
              ),
            ],
            if (_endType == ScheduleRecurrenceEndType.count) ...[
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('schedule-recurrence-count'),
                controller: _countController,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'schedule_repeat_occurrences'.tr(),
                ),
                validator: (value) {
                  if (_frequency == null ||
                      _endType != ScheduleRecurrenceEndType.count) {
                    return null;
                  }
                  final count = int.tryParse(value ?? '');
                  return count == null || count < 1 || count > 999
                      ? 'schedule_repeat_count_invalid'.tr()
                      : null;
                },
                onChanged: (_) => _emit(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'schedule_repeat_series_hint'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _frequencyLabel(ScheduleRecurrenceFrequency frequency) =>
      switch (frequency) {
        ScheduleRecurrenceFrequency.daily => 'schedule_repeat_daily'.tr(),
        ScheduleRecurrenceFrequency.weekly => 'schedule_repeat_weekly'.tr(),
        ScheduleRecurrenceFrequency.monthly => 'schedule_repeat_monthly'.tr(),
      };

  String _endTypeLabel(ScheduleRecurrenceEndType endType) => switch (endType) {
    ScheduleRecurrenceEndType.never => 'schedule_repeat_never'.tr(),
    ScheduleRecurrenceEndType.until => 'schedule_repeat_until'.tr(),
    ScheduleRecurrenceEndType.count => 'schedule_repeat_count'.tr(),
  };

  String _weekdayLabel(BuildContext context, int weekday) {
    final monday = DateTime(2024, 1, 1);
    return DateFormat.E(
      context.locale.toString(),
    ).format(monday.add(Duration(days: weekday - 1)));
  }

  Future<void> _pickUntil() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _until,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _until = picked);
    _emit();
  }

  void _emit() {
    if (_frequency == null) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged(
      ScheduleRecurrence(
        frequency: _frequency!,
        interval: int.tryParse(_intervalController.text) ?? 1,
        weekdays: _frequency == ScheduleRecurrenceFrequency.weekly
            ? (_weekdays.toList()..sort())
            : const [],
        endType: _endType,
        until: _endType == ScheduleRecurrenceEndType.until
            ? DateTime.utc(_until.year, _until.month, _until.day, 23, 59, 59)
            : null,
        count: _endType == ScheduleRecurrenceEndType.count
            ? int.tryParse(_countController.text)
            : null,
      ),
    );
  }
}

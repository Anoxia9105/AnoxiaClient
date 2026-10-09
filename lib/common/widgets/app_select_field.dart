import 'package:flutter/material.dart';

class AppSelectOption<T> {
  final T value;
  final String label;
  final bool enabled;

  const AppSelectOption({
    required this.value,
    required this.label,
    this.enabled = true,
  });
}

class AppSelectField<T> extends StatelessWidget {
  final T value;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T> onChanged;
  final String label;
  final IconData? icon;
  final bool enabled;
  final InputDecoration? decoration;

  const AppSelectField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.label,
    required this.enabled,
    this.icon,
    this.decoration,
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
            decoration: (decoration ?? const InputDecoration()).copyWith(
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
              onPressed: enabled && option.enabled
                  ? () => onChanged(option.value)
                  : null,
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

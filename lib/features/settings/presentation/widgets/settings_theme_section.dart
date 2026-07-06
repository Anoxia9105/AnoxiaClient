import 'package:anoxia/framework/theme/AppTheme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'settings_item_card.dart';

class SettingsThemeSection extends StatelessWidget {
  final Brightness selectedBrightness;
  final int selectedAccentIndex;
  final ValueChanged<Brightness> onBrightnessChanged;
  final ValueChanged<int> onAccentChanged;

  const SettingsThemeSection({
    super.key,
    required this.selectedBrightness,
    required this.selectedAccentIndex,
    required this.onBrightnessChanged,
    required this.onAccentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingItemCard(
      title: 'settings_page_theme_title'.tr(),
      subtitle: 'settings_page_theme_subtitle'.tr(),
      icon: HugeIcons.strokeRoundedColors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: 'settings_theme_mode'.tr()),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _BrightnessTile(
                  label: 'settings_theme_light'.tr(),
                  icon: HugeIcons.strokeRoundedSun03,
                  brightness: Brightness.light,
                  selectedBrightness: selectedBrightness,
                  onChanged: onBrightnessChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BrightnessTile(
                  label: 'settings_theme_dark'.tr(),
                  icon: HugeIcons.strokeRoundedMoon02,
                  brightness: Brightness.dark,
                  selectedBrightness: selectedBrightness,
                  onChanged: onBrightnessChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionLabel(text: 'settings_theme_accent_color'.tr()),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (
                  var index = 0;
                  index < AppTheme.accentOptions.length;
                  index++
                ) ...[
                  _AccentSwatch(
                    color: AppTheme.accentOptions[index].color,
                    label: AppTheme.accentOptions[index].localizedName,
                    selected: selectedAccentIndex == index,
                    onTap: () => onAccentChanged(index),
                  ),
                  if (index != AppTheme.accentOptions.length - 1)
                    const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _BrightnessTile extends StatelessWidget {
  final String label;
  final List<List<dynamic>> icon;
  final Brightness brightness;
  final Brightness selectedBrightness;
  final ValueChanged<Brightness> onChanged;

  const _BrightnessTile({
    required this.label,
    required this.icon,
    required this.brightness,
    required this.selectedBrightness,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = brightness == selectedBrightness;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      mouseCursor: SystemMouseCursors.click,
      onTap: () => onChanged(brightness),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              size: 20,
              color: selected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 18, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AccentSwatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shadowColor = color.withValues(alpha: selected ? 0.34 : 0.18);

    return Tooltip(
      message: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: selected ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  HSLColor.fromColor(
                    color,
                  ).withLightness(0.68).withSaturation(0.72).toColor(),
                  color,
                  HSLColor.fromColor(
                    color,
                  ).withLightness(0.34).withSaturation(0.66).toColor(),
                ],
              ),
              border: Border.all(
                color: colorScheme.surface.withValues(alpha: 0.82),
                width: 1.4,
              ),
            ),
            child: selected
                ? Icon(
                    Icons.check_rounded,
                    color: colorScheme.onPrimary,
                    size: 18,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

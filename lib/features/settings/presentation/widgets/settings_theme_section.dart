import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';

import 'settings_theme_widgets.dart';

/// 设置-主题区块
///
/// 提供亮暗主题切换、分组强调色选择与自定义取色功能。
class SettingsThemeSection extends ConsumerWidget {
  /// 亮度变更回调
  final ValueChanged<Brightness> onBrightnessChanged;

  /// 强调色变更回调
  final ValueChanged<int> onAccentChanged;

  /// 自定义颜色变更
  final ValueChanged<Color?> onCustomColorChanged;

  const SettingsThemeSection({
    super.key,
    required this.onBrightnessChanged,
    required this.onAccentChanged,
    required this.onCustomColorChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBrightness = ref.watch(themeModeProvider);
    final selectedAccentIndex = ref.watch(themeAccentProvider);
    final customColor = ref.watch(customAccentColorProvider);
    final grouped = AppTheme.groupedAccentIndices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(text: 'settings_theme_mode'.tr()),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: BrightnessTile(
                label: 'settings_theme_light'.tr(),
                icon: HugeIcons.strokeRoundedSun03,
                brightness: Brightness.light,
                selectedBrightness: selectedBrightness,
                onChanged: onBrightnessChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BrightnessTile(
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
        SectionLabel(text: 'settings_theme_accent_color'.tr()),
        const SizedBox(height: SpacingToken.sm),
        // 分组展示
        for (final category in AccentCategory.values) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              category.localizedLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final index in grouped[category]!)
                AccentSwatch(
                  color: AppTheme.accentOptions[index].color,
                  label: AppTheme.accentOptions[index].localizedName,
                  selected: customColor == null && selectedAccentIndex == index,
                  onTap: () {
                    onCustomColorChanged(null);
                    onAccentChanged(index);
                  },
                ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        // 自定义取色
        SectionLabel(text: 'settings_theme_custom_color'.tr()),
        const SizedBox(height: 10),
        CustomColorRow(
          customColor: customColor,
          onPick: (color) => onCustomColorChanged(color),
          onClear: () => onCustomColorChanged(null),
        ),
      ],
    );
  }
}

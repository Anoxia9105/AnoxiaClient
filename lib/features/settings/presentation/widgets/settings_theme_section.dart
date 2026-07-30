import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'settings_item_card.dart';

/// 设置-主题区块
///
/// 提供亮暗主题切换和强调色选择功能，包含亮度模式选择卡片
/// 和强调色色块列表。

/// 设置-主题区块组件
///
/// 提供亮度模式（亮色/暗色）和强调色选择的 UI 控件。
class SettingsThemeSection extends StatelessWidget {
  /// 当前选中的亮度
  final Brightness selectedBrightness;

  /// 当前选中的强调色索引
  final int selectedAccentIndex;

  /// 亮度变更回调
  final ValueChanged<Brightness> onBrightnessChanged;

  /// 强调色变更回调
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

/// 分区标签组件
///
/// 用于主题区块内分组的标签文字。
class _SectionLabel extends StatelessWidget {
  /// 标签文本
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

/// 亮度选择卡片
///
/// 用于选择亮色或暗色主题的可点击卡片，选中时高亮显示。
class _BrightnessTile extends StatelessWidget {
  /// 标签文本
  final String label;

  /// 图标
  final List<List<dynamic>> icon;

  /// 亮度值
  final Brightness brightness;

  /// 当前选中的亮度
  final Brightness selectedBrightness;

  /// 变更回调
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

/// 强调色色块
///
/// 圆形渐变色块，用于选择主题强调色，选中时显示边框和勾选图标。
class _AccentSwatch extends StatelessWidget {
  /// 颜色值
  final Color color;

  /// 颜色名称
  final String label;

  /// 是否选中
  final bool selected;

  /// 点击回调
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

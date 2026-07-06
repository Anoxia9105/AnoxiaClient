import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'settings_item_card.dart';

/// 字体设置组件
///
/// 提供全局字体选择功能，选择后会实时应用到全应用。
class SettingsFontSection extends StatelessWidget {
  final String selectedFontKey;
  final bool isDesktop;
  final ValueChanged<String> onFontChanged;

  const SettingsFontSection({
    super.key,
    required this.selectedFontKey,
    required this.isDesktop,
    required this.onFontChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingItemCard(
      title: 'settings_page_fonts_title'.tr(),
      subtitle: 'settings_page_fonts_subtitle'.tr(),
      icon: HugeIcons.strokeRoundedText,
      child: Column(
        children: [
          for (var index = 0; index < appFontOptions.length; index++) ...[
            _FontOptionTile(
              label: appFontOptions[index].labelKey.tr(),
              fontKey: appFontOptions[index].key,
              selectedFontKey: selectedFontKey,
              onFontChanged: onFontChanged,
            ),
            if (index != appFontOptions.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _FontOptionTile extends StatelessWidget {
  final String label;
  final String fontKey;
  final String selectedFontKey;
  final ValueChanged<String> onFontChanged;

  const _FontOptionTile({
    required this.label,
    required this.fontKey,
    required this.selectedFontKey,
    required this.onFontChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = selectedFontKey == fontKey;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      mouseCursor: SystemMouseCursors.click,
      onTap: () => onFontChanged(fontKey),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.75),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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

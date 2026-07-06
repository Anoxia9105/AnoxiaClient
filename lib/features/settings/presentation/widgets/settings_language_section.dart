import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'settings_item_card.dart';

/// 语言设置组件
///
/// 提供应用语言选择功能，支持英语、中文、日语等多语言切换
class SettingsLanguageSection extends StatelessWidget {
  final String selectedLanguageCode;
  final bool isDesktop;
  final ValueChanged<String> onLanguageChanged;

  const SettingsLanguageSection({
    super.key,
    required this.selectedLanguageCode,
    required this.isDesktop,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingItemCard(
      title: 'settings_page_language_title'.tr(),
      subtitle: 'settings_page_language_subtitle'.tr(),
      icon: HugeIcons.strokeRoundedLanguageSquare,
      child: Column(
        children: [
          _LanguageOption(
            label: 'settings_language_chinese'.tr(),
            value: 'zh',
            selectedLanguageCode: selectedLanguageCode,
            onLanguageChanged: onLanguageChanged,
          ),
          const SizedBox(height: 8),
          _LanguageOption(
            label: 'settings_language_english'.tr(),
            value: 'en',
            selectedLanguageCode: selectedLanguageCode,
            onLanguageChanged: onLanguageChanged,
          ),
          const SizedBox(height: 8),
          _LanguageOption(
            label: 'settings_language_japanese'.tr(),
            value: 'ja',
            selectedLanguageCode: selectedLanguageCode,
            onLanguageChanged: onLanguageChanged,
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String value;
  final String selectedLanguageCode;
  final ValueChanged<String> onLanguageChanged;

  const _LanguageOption({
    required this.label,
    required this.value,
    required this.selectedLanguageCode,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = selectedLanguageCode == value;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onLanguageChanged(value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
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
                  fontWeight: FontWeight.w700,
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

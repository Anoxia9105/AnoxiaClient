import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'settings_item_card.dart';

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
      child: Row(
        children: [
          const Expanded(flex: 2, child: SizedBox.shrink()),
          Expanded(
            flex: isDesktop ? 1 : 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: DropdownButtonFormField<String>(
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                icon: const Icon(Icons.expand_more),
                initialValue: selectedLanguageCode,
                items: [
                  DropdownMenuItem(
                    value: 'en',
                    child: Text('settings_language_english'.tr()),
                  ),
                  DropdownMenuItem(
                    value: 'zh',
                    child: Text('settings_language_chinese'.tr()),
                  ),
                  DropdownMenuItem(
                    value: 'ja',
                    child: Text('settings_language_japanese'.tr()),
                  ),
                ],
                onChanged: (locale) {
                  if (locale != null) onLanguageChanged(locale);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

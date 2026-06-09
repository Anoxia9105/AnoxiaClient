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
                initialValue: selectedFontKey,
                items: appFontOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option.key,
                        child: Text(option.labelKey.tr()),
                      ),
                    )
                    .toList(),
                onChanged: (fontKey) {
                  if (fontKey != null) onFontChanged(fontKey);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

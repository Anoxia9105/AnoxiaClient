import 'package:anoxia/framework/theme/AppTheme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'settings_item_card.dart';

class SettingsThemeSection extends StatelessWidget {
  final int selectedThemeIndex;
  final ValueChanged<int> onThemeChanged;

  const SettingsThemeSection({
    super.key,
    required this.selectedThemeIndex,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingItemCard(
      title: 'settings_page_theme_title'.tr(),
      subtitle: 'settings_page_theme_subtitle'.tr(),
      icon: HugeIcons.strokeRoundedColors,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(AppTheme.themes.length, (index) {
              final isSelected = selectedThemeIndex == index;
              final theme = AppTheme.themes[index];

              return SizedBox(
                width: itemWidth,
                child: InkWell(
                  onTap: () => onThemeChanged(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade900
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: theme.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            theme.localizedName,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

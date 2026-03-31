import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../common/utils/DeviceUtil.dart';
import '../../framework/theme/AppTheme.dart';
import 'SettingItemCard.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeIndex = ref.watch(themeIndexProvider);
    final callWin = ref.read(callWindowControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text("settings_page_title".tr())),
      body: ListView(
        children: [
          // 主题设置
          SettingItemCard(
            title: "settings_page_theme_title".tr(),
            subtitle: "settings_page_theme_subtitle".tr(),
            icon: HugeIcons.strokeRoundedColors,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 8) / 2; // 8 是 spacing
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(AppTheme.themes.length, (index) {
                    final isSelected = themeIndex == index;

                    final theme = AppTheme.themes[index];
                    return SizedBox(
                      width: itemWidth,
                      child: InkWell(
                        onTap: () {
                          ref.read(themeIndexProvider.notifier).setTheme(index);
                          if (callWin != null) {
                            ref
                                .read(callWindowControllerProvider.notifier)
                                .updateSettings(themeIndex: index);
                          }
                        },
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
                                  : Theme.of(context).brightness ==
                                        Brightness.dark
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
          ),

          // 语言设置
          SettingItemCard(
            title: "settings_page_language_title".tr(),
            subtitle: "settings_page_language_subtitle".tr(),
            icon: HugeIcons.strokeRoundedLanguageSquare,
            child: Row(
              children: [
                Expanded(flex: 2, child: SizedBox.shrink()),
                Expanded(
                  flex: DeviceUtil.isDesktop(context) ? 1 : 2,
                  child: Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        // fontFamily: setting.fontFamily,
                      ),
                      icon: Icon(Icons.expand_more),
                      initialValue: context.locale.languageCode,
                      items:  [
                        DropdownMenuItem(value: 'en', child: Text('settings_language_english'.tr())),
                        DropdownMenuItem(value: 'zh', child: Text('settings_language_chinese'.tr())),
                        DropdownMenuItem(value: 'ja', child: Text('settings_language_japanese'.tr())),
                      ],
                      onChanged: (locale) {
                        if (locale != null) {
                          context.setLocale(Locale(locale));
                          if (callWin != null) {
                            ref
                                .read(callWindowControllerProvider.notifier)
                                .updateSettings(localeCode: locale);
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          //关于与支持
          SettingItemCard(
            title: "settings_page_about_title".tr(),
            subtitle: "settings_page_about_subtitle".tr(),
            icon: HugeIcons.strokeRoundedLink01,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 30),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedQuillWrite01,
                      size: 18,
                    ),
                    title: Text('settings_app_name'.tr()),
                    trailing: Text("Anoxia", style: TextStyle(fontSize: 14)),
                  ),
                  ListTile(
                    dense: true,
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedSortByUp01,
                      size: 18,
                    ),
                    title: Text('settings_app_version'.tr()),
                    trailing: Text("1.0.0", style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

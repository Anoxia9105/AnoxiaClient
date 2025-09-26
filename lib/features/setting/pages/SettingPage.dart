import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:notepadclient/core/di/injector.dart';
import 'package:notepadclient/core/utils/DeviceUtil.dart';
import 'package:notepadclient/features/setting/controller/SettingsController.dart';
import 'package:notepadclient/features/setting/widgets/SettingItemCard.dart';
import 'package:notepadclient/shared/theme/AppTheme.dart';
import 'package:notepadclient/shared/widgets/FocusOverlayManager.dart';

final SettingsController settingsController = getIt<SettingsController>();

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          FocusOverlayManager.show(
            context,
            FilledButton(
              onPressed: () => FocusOverlayManager.hide(),
              child: Text('Close'),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
      appBar: AppBar(title: Text("settings_page_title".tr())),
      body: ListView(
        children: [
          // 主题设置
          SettingItemCard(
            title: "settings_page_theme_title".tr(),
            subtitle: "settings_page_theme_subtitle".tr(),
            icon: Icons.color_lens,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 8) / 2; // 8 是 spacing
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(AppTheme.themes.length, (index) {
                    final isSelected = settingsController.themeIndex == index;
                    final theme = AppTheme.themes[index];
                    return SizedBox(
                      width: itemWidth,
                      child: InkWell(
                        onTap: () => settingsController.setThemeMode(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  isSelected
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
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color:
                                        isSelected
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
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
            icon: Icons.language,
            child: Row(
              children: [
                Expanded(flex: 2, child: SizedBox.shrink()),
                Expanded(
                  flex: DeviceUtil.isDesktop(context) ? 1 : 2,
                  child: Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: DropdownButtonFormField<Locale>(
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      icon: Icon(Icons.expand_more),
                      value: context.locale,
                      items: const [
                        DropdownMenuItem(
                          value: Locale('en'),
                          child: Text("English"),
                        ),
                        DropdownMenuItem(
                          value: Locale('zh'),
                          child: Text("中文"),
                        ),
                        DropdownMenuItem(
                          value: Locale('ja'),
                          child: Text("日本語"),
                        ),
                      ],
                      onChanged: (locale) {
                        if (locale != null) {
                          context.setLocale(locale);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

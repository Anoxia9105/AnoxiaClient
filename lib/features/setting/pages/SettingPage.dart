import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/Flavor.dart';
import 'package:notepadclient/core/di/injector.dart';
import 'package:notepadclient/core/enums/LayoutType.dart';
import 'package:notepadclient/core/utils/DateUtil.dart';
import 'package:notepadclient/core/utils/DeviceUtil.dart';
import 'package:notepadclient/features/setting/controller/SettingsController.dart';
import 'package:notepadclient/features/setting/widgets/SettingItemCard.dart';
import 'package:notepadclient/shared/theme/AppColors.dart';
import 'package:notepadclient/shared/theme/AppTheme.dart';
import 'package:notepadclient/shared/widgets/FocusOverlayManager.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';


class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {

    final setting= context.read<SettingsController>();
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () {
        //     FocusOverlayManager.show(
        //       context,
        //       FilledButton(
        //         onPressed: () => FocusOverlayManager.hide(),
        //         child: Text('Close'),
        //       ),
        //     );
        //   },
        //   child: Icon(Icons.add),
        // ),
        appBar: DeviceUtil.isRealDesktop()
            ? AppBar(
                title: Text("settings_page_title".tr()),
                flexibleSpace: const DragToMoveArea(child: SizedBox.expand()),
              )
            : AppBar(title: Text("settings_page_title".tr())),
        body: ListView(
          children: [
            // 主题设置
            SettingItemCard(
              title: "settings_page_theme_title".tr(),
              subtitle: "settings_page_theme_subtitle".tr(),
              icon: HugeIcons.strokeRoundedColors,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth =
                      (constraints.maxWidth - 8) / 2; // 8 是 spacing
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(AppTheme.themes.length, (index) {
                      final isSelected = setting.themeIndex == index;
                      final theme = AppTheme.themes[index];
                      return SizedBox(
                        width: itemWidth,
                        child: InkWell(
                          onTap: () => setting.setThemeMode(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha:0.1)
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
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
                      child: DropdownButtonFormField<Locale>(
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: setting.fontFamily,
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

            // 字体设置
            SettingItemCard(
              title: "settings_page_fonts_title".tr(),
              subtitle: "settings_page_fonts_subtitle".tr(),
              icon: HugeIcons.strokeRoundedTextFont,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 2, child: SizedBox.shrink()),

                  SizedBox(width: 10),
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
                          fontFamily: setting.fontFamily,
                        ),
                        icon: Icon(Icons.expand_more),
                        initialValue: setting.fontFamily,
                        items: const [
                          DropdownMenuItem(
                            value: "HarmonyOS",
                            child: Text("鸿蒙黑体"),
                          ),
                          DropdownMenuItem(
                            value: "ZhiyiMaru",
                            child: Text("致圆黑体"),
                          ),
                          DropdownMenuItem(
                            value: "SourceHanSerifCN",
                            child: Text("宋体"),
                          ),
                        ],
                        onChanged: (font) {
                          if (font != null) {
                            setting.setFontFamily(font);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 布局设置
            SettingItemCard(
              title: "settings_page_layout_title".tr(),
              subtitle: "settings_page_layout_subtitle".tr(),
              icon: HugeIcons.strokeRoundedLayout01,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 2, child: SizedBox.shrink()),
                  SizedBox(width: 10),
                  Expanded(
                    flex: DeviceUtil.isDesktop(context) ? 1 : 2,
                    child: Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: DropdownButtonFormField<LayoutType>(
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: setting.fontFamily,
                        ),
                        icon: Icon(Icons.expand_more),
                        initialValue: setting.layoutType,
                        items: const [
                          DropdownMenuItem(
                            value: LayoutType.card,
                            child: Text("卡片方式布局"),
                          ),
                          DropdownMenuItem(
                            value: LayoutType.tiling,
                            child: Text("平铺方式布局"),
                          ),
                        ],
                        onChanged: (layout) {
                          if (layout != null) {
                            setting.setLayoutType(layout);
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
                padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 30),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedQuillWrite01,size: 18),
                      title: Text("程序名称"),
                      trailing: Text(FlavorConfig.value.appName,style: TextStyle(fontSize: 14),),
                    ),
                    ListTile(
                      dense: true,
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedSortByUp01,size: 18),
                      title: Text("程序版本"),
                      trailing: Text(FlavorConfig.value.appVersion,style: TextStyle(fontSize: 14),),
                    ),
                    ListTile(
                      dense: true,
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedCalendar03,size: 18),
                      title: Text("构建时间"),
                      trailing: Text(DateUtil.formatIsoDate(FlavorConfig.value.buildDate),style: TextStyle(fontSize: 14),),
                    )
                  ],
                )

              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$label: ", style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
import 'package:anoxia/common/constants/storage_keys.dart';
import 'package:anoxia/common/utils/sp_util.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'error_page.dart';
import 'error_page_strings.dart';

/// 不依赖业务 Provider 或 EasyLocalization 的启动失败壳。
/// 直接读取已初始化的偏好；存储不可用时仍可展示错误页面。
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.details, this.onClose});

  final String details;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    var mode = ThemeMode.light;
    var accentIndex = 0;
    Color? customColor;
    try {
      final storage = SPUtil.instance;
      mode = switch (storage.get('theme_brightness')) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };
      accentIndex = storage.getInt('theme_accent_index', defValue: 0) ?? 0;
      if (storage.getBool(StorageKeys.customAccentEnabled, defValue: false) ==
          true) {
        final value = storage.getInt(StorageKeys.customAccentColor);
        if (value != null) customColor = Color(value);
      }
    } catch (_) {}

    ThemeData theme(Brightness brightness) => customColor != null
        ? AppTheme.getThemeForCustomColor(
            brightness: brightness,
            color: customColor,
          )
        : AppTheme.getThemeByModeAndAccent(
            brightness: brightness,
            accentIndex: accentIndex,
          );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: ErrorPageStrings.startupLocale(),
      supportedLocales: const [Locale('zh'), Locale('en'), Locale('ja')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: mode,
      home: ErrorPage(startup: true, details: details, onClose: onClose),
    );
  }
}

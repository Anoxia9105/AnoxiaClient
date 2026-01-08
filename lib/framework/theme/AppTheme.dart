import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'ThemeMixin.dart';

class AppTheme with ThemeMixin {
  AppTheme._(); // 禁止实例化

  /// 主题元数据
  static final List<ThemeOption> themes = [
    ThemeOption(
      'app_light_themes1',
      Colors.indigo,
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE6E6E9), Color(0xFFEAE6DB)],
      ),
    ),
    ThemeOption(
      'app_light_themes2',
      Colors.lightGreen,
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFDEE4EA), Color(0xFFC3CBD6)],
      ),
    ),
    ThemeOption(
      'app_light_themes3',
      Colors.pink,
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF0F5), Color(0xFFFEF9F3)],
      ),
    ),
    ThemeOption(
      'app_light_themes4',
      Colors.teal,
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF0FFFF), Color(0xFFF5FFFA)],
      ),
    ),
    ThemeOption(
      'app_light_themes5',
      Colors.blueGrey,
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
      ),
    ),
    ThemeOption(
      'app_light_themes6',
      Colors.orange,
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFFFFDE7)],
      ),
    ),
    ThemeOption(
      'app_light_themes7',
      Colors.deepPurple,
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF3E5F5), Color(0xFFFFFFFF)],
      ),
    ),
    ThemeOption(
      'app_dark_themes8',
      Colors.blue,
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D0221), Color(0xFF241744)],
      ),
    ),
    ThemeOption(
      'app_dark_themes9',
      Colors.purple,
      Brightness.light,
       LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
              Colors.blue.shade200,
              Colors.purple.shade200,
        ],
      ),
    ),
    ThemeOption(
      'app_dark_themes10',
      const Color(0xFF2B2B2B),
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF555555), Color(0xFF333333)],
      ),
    ),
    ThemeOption(
      '测试1',
      const Color(0xFF2B2B2B),
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.topRight,
        colors: [Color(0xFFC9D6FF), Color(0xFFE2E2E2)],
      ),
    ),
  ];

  /// 根据 index 获取 ThemeData
  static ThemeData getTheme({int? index,String? overrideFontFamily}) {
    final idx = (index == null || index < 0 || index >= themes.length) ? 0 : index;
    final t = themes[idx];
    return ThemeMixin.buildTheme(
      brightness: t.brightness,
      primaryColor: t.color,
      gradient: t.gradient,
      fontFamily: overrideFontFamily ?? t.fontFamily,
    );
  }
}

/// 主题元数据类
class ThemeOption {
  final String name;
  final Color? color;
  final Brightness brightness;
  final LinearGradient gradient;
  final String? fontFamily;

  const ThemeOption(this.name, this.color, this.brightness, this.gradient, {this.fontFamily});

  String get localizedName => name.tr();
}

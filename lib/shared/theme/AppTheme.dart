import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:notepadclient/shared/theme/ThemeMixin.dart';

class AppTheme with ThemeMixin {
  AppTheme._(); // 禁止实例化

  /// 主题元数据
  static final List<ThemeOption> themes = [
    ThemeOption(
      'app_light_themes1',
      Colors.indigo,
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE6E6E9), Color(0xFFEAE6DB)],
      ),
    ),
    ThemeOption(
      'app_light_themes2',
      Colors.green,
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
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
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
      Colors.pinkAccent,
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF000428), Color(0xFF004e92)],
      ),
    ),
    ThemeOption(
      'app_dark_themes10',
      Colors.greenAccent,
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF101D21), Color(0xFF092E21)],
      ),
    ),
    ThemeOption(
      'app_dark_themes11',
      Colors.amber,
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3E2723), Color(0xFF000000)],
      ),
    ),
    ThemeOption(
      'app_dark_themes12',
      Colors.redAccent,
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF641E16), Color(0xFF1B0000)],
      ),
    ),
    ThemeOption(
      'app_dark_themes13',
      Colors.cyan,
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF003942), Color(0xFF011A20)],
      ),
    ),
    ThemeOption(
      'app_dark_themes14',
      const Color(0xFF8D6E63),
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2E1E1A), Color(0xFF1A0A06)],
      ),
    ),
    ThemeOption(
      'app_dark_themes15',
      Colors.purpleAccent,
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2C0747), Color(0xFF0F0219)],
      ),
    ),
    ThemeOption(
      'app_dark_themes16',
      const Color(0xFF69F0AE),
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF01180A), Color(0xFF000000)],
      ),
    ),
    ThemeOption(
      'app_dark_themes17',
      Colors.orange,
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2C1D38), Color(0xFF532432)],
      ),
    ),
    ThemeOption(
      'app_dark_themes18',
      Colors.blue,
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF14293D), Color(0xFF030D1A)],
      ),
    ),
    ThemeOption(
      'app_dark_themes19',
      const Color(0xFF2B2B2B),
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF555555), Color(0xFF333333)],
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

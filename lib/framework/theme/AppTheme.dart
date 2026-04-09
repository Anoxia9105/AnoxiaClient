import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'ThemeMixin.dart';

class AppTheme with ThemeMixin {
  AppTheme._();

  static final List<ThemeOption> themes = [
    // ==================== 亮色主题系列 ====================
    ThemeOption(
      'app_light_themes1',
      const Color(0xFF5A5FD6), // Indigo - 降低饱和，更沉稳
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF4F5FB), Color(0xFFEAECF8)], // 带蓝调的米白，不再纯白刺眼
      ),
    ),
    ThemeOption(
      'app_light_themes2',
      const Color(0xFF0E9E72), // Emerald - 稍暗
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEFF9F4), Color(0xFFD6F5E8)], // 柔和绿白
      ),
    ),
    ThemeOption(
      'app_light_themes3',
      const Color(0xFFD45F9A), // Pink - 降饱和，更柔和
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFCF0F5), Color(0xFFF8E6EF)], // 奶粉色，不再荧光
      ),
    ),
    ThemeOption(
      'app_light_themes4',
      const Color(0xFF0FA090), // Teal - 稍深
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEEFAF8), Color(0xFFD5F4F0)],
      ),
    ),
    ThemeOption(
      'app_light_themes5',
      const Color(0xFF5A6172), // Gray - 偏蓝灰，更有质感
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF5F5F7), Color(0xFFECEDF0)], // 带冷调的灰白，不再死白
      ),
    ),
    ThemeOption(
      'app_light_themes6',
      const Color(0xFFD48A10), // Amber - 降亮度
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFBF5E6), Color(0xFFF5E8C2)], // 奶油黄，不再刺眼
      ),
    ),
    ThemeOption(
      'app_light_themes7',
      const Color(0xFF7250D4), // Violet - 降亮度
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF2EFF9), Color(0xFFE8E2F6)], // 淡薰衣草
      ),
    ),

    // ==================== 暗色主题系列 ====================
    ThemeOption(
      'app_dark_themes8',
      const Color(0xFF6BA3E8), // Blue - 降亮，去除荧光感
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D1520), Color(0xFF162032)], // 更深邃，不偏绿
      ),
    ),
    ThemeOption(
      'app_dark_themes9',
      const Color(0xFF9370CC), // Purple - 降饱和
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1730), Color(0xFF2A2550)],
      ),
    ),
    ThemeOption(
      'app_dark_themes10',
      const Color(0xFF52C49A), // Emerald - 降亮
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0E3530), Color(0xFF0F4A44)],
      ),
    ),
    ThemeOption(
      'app_dark_themes11',
      const Color(0xFFD4A030), // Amber - 降亮，更古铜
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2A1500), Color(0xFF4A2800)],
      ),
    ),
    ThemeOption(
      'app_dark_themes12',
      const Color(0xFFD46060), // Red - 降亮，不再荧光红
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF200A0A), Color(0xFF3A0E0E)],
      ),
    ),
    ThemeOption(
      'app_dark_themes13',
      const Color(0xFF3E9FD4), // Sky - 降饱和
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF082030), Color(0xFF0A3A52)],
      ),
    ),
    ThemeOption(
      'app_dark_themes14',
      const Color(0xFFB86A20), // Amber - 更深沉
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E1208), Color(0xFF352010)],
      ),
    ),
    ThemeOption(
      'app_dark_themes15',
      const Color(0xFFAA6EE0), // Purple - 降亮
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E0A48), Color(0xFF350E70)],
      ),
    ),
    ThemeOption(
      'app_dark_themes16',
      const Color(0xFF38A85A), // Green - 降亮，去荧光
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF021A10), Color(0xFF043020)],
      ),
    ),
    ThemeOption(
      'app_dark_themes17',
      const Color(0xFFD4662A), // Orange - 降亮
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2A0D04), Color(0xFF4E1A08)],
      ),
    ),
    ThemeOption(
      'app_dark_themes18',
      const Color(0xFF4ECCE0), // Cyan - 降亮，去荧光
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF082A35), Color(0xFF0A4050)],
      ),
    ),
    ThemeOption(
      'app_dark_themes19',
      const Color(0xFF8A9099), // Gray - 微暖调
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF141416), Color(0xFF1E2022)], // 带点暖意，不再死黑
      ),
    ),
  ];

  static ThemeData getTheme({int? index, String? overrideFontFamily}) {
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

class ThemeOption {
  final String name;
  final Color? color;
  final Brightness brightness;
  final LinearGradient gradient;
  final String? fontFamily;

  const ThemeOption(this.name, this.color, this.brightness, this.gradient, {this.fontFamily});

  String get localizedName => name.tr();
}
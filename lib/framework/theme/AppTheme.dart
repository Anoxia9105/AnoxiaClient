import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'ThemeMixin.dart';

/// 应用主题管理类
///
/// 提供多个预定义的亮色和暗色主题，支持主题切换
class AppTheme with ThemeMixin {
  AppTheme._();

  /// 所有可用主题选项列表
  ///
  /// 包含7个亮色主题和12个暗色主题，每个主题都有独特的配色方案
  static final List<ThemeOption> themes = [
    // ==================== 亮色主题系列 ====================
    const ThemeOption(
      'app_light_themes1',
      Color(0xFF5A5FD6), // Indigo - 降低饱和，更沉稳
      Brightness.light,
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF4F5FB), Color(0xFFEAECF8)], // 带蓝调的米白，不再纯白刺眼
      ),
    ),
    const ThemeOption(
      'app_light_themes2',
      Color(0xFF0E9E72), // Emerald - 稍暗
      Brightness.light,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEFF9F4), Color(0xFFD6F5E8)], // 柔和绿白
      ),
    ),
    const ThemeOption(
      'app_light_themes3',
      Color(0xFFD45F9A), // Pink - 降饱和，更柔和
      Brightness.light,
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFCF0F5), Color(0xFFF8E6EF)], // 奶粉色，不再荧光
      ),
    ),
    const ThemeOption(
      'app_light_themes4',
      Color(0xFF0FA090), // Teal - 稍深
      Brightness.light,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEEFAF8), Color(0xFFD5F4F0)],
      ),
    ),
    const ThemeOption(
      'app_light_themes5',
      Color(0xFF5A6172), // Gray - 偏蓝灰，更有质感
      Brightness.light,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF5F5F7), Color(0xFFECEDF0)], // 带冷调的灰白，不再死白
      ),
    ),
    const ThemeOption(
      'app_light_themes6',
      Color(0xFFD48A10), // Amber - 降亮度
      Brightness.light,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFBF5E6), Color(0xFFF5E8C2)], // 奶油黄，不再刺眼
      ),
    ),
    const ThemeOption(
      'app_light_themes7',
      Color(0xFF7250D4), // Violet - 降亮度
      Brightness.light,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF2EFF9), Color(0xFFE8E2F6)], // 淡薰衣草
      ),
    ),

    // ==================== 暗色主题系列 ====================
    const ThemeOption(
      'app_dark_themes8',
      Color(0xFF6BA3E8), // Blue - 降亮，去除荧光感
      Brightness.dark,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D1520), Color(0xFF162032)], // 更深邃，不偏绿
      ),
    ),
    const ThemeOption(
      'app_dark_themes9',
      Color(0xFF9370CC), // Purple - 降饱和
      Brightness.dark,
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1730), Color(0xFF2A2550)],
      ),
    ),
    const ThemeOption(
      'app_dark_themes10',
      Color(0xFF52C49A), // Emerald - 降亮
      Brightness.dark,
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0E3530), Color(0xFF0F4A44)],
      ),
    ),
    const ThemeOption(
      'app_dark_themes11',
      Color(0xFFD4A030), // Amber - 降亮，更古铜
      Brightness.dark,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2A1500), Color(0xFF4A2800)],
      ),
    ),
    const ThemeOption(
      'app_dark_themes12',
      Color(0xFFD46060), // Red - 降亮，不再荧光红
      Brightness.dark,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF200A0A), Color(0xFF3A0E0E)],
      ),
    ),
    const ThemeOption(
      'app_dark_themes13',
      Color(0xFF3E9FD4), // Sky - 降饱和
      Brightness.dark,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF082030), Color(0xFF0A3A52)],
      ),
    ),
    const ThemeOption(
      'app_dark_themes14',
      Color(0xFFB86A20), // Amber - 更深沉
      Brightness.dark,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E1208), Color(0xFF352010)],
      ),
    ),
    const ThemeOption(
      'app_dark_themes15',
      Color(0xFFAA6EE0), // Purple - 降亮
      Brightness.dark,
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E0A48), Color(0xFF350E70)],
      ),
    ),
    const ThemeOption(
      'app_dark_themes16',
      Color(0xFF38A85A), // Green - 降亮，去荧光
      Brightness.dark,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF021A10), Color(0xFF043020)],
      ),
    ),
    const ThemeOption(
      'app_dark_themes17',
      Color(0xFFD4662A), // Orange - 降亮
      Brightness.dark,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2A0D04), Color(0xFF4E1A08)],
      ),
    ),
    const ThemeOption(
      'app_dark_themes18',
      Color(0xFF4ECCE0), // Cyan - 降亮，去荧光
      Brightness.dark,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF082A35), Color(0xFF0A4050)],
      ),
    ),
    const ThemeOption(
      'app_dark_themes19',
      Color(0xFF8A9099), // Gray - 微暖调
      Brightness.dark,
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF141416), Color(0xFF1E2022)], // 带点暖意，不再死黑
      ),
    ),
  ];

  /// 获取指定索引的主题数据
  ///
  /// [index] 主题索引，若为 null 或越界则使用默认主题
  /// [overrideFontFamily] 可选，覆盖主题默认字体
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

/// 主题选项配置类
///
/// 定义单个主题的完整配置信息
class ThemeOption {
  /// 主题名称（用于国际化）
  final String name;
  /// 主题主色调
  final Color? color;
  /// 主题亮度（亮色/暗色）
  final Brightness brightness;
  /// 背景渐变
  final LinearGradient gradient;
  /// 主题字体（可选）
  final String? fontFamily;

  /// 创建主题选项
  ///
  /// [name] 主题名称键
  /// [color] 主题主色调
  /// [brightness] 亮度模式
  /// [gradient] 背景渐变
  /// [fontFamily] 可选字体
  const ThemeOption(this.name, this.color, this.brightness, this.gradient, {this.fontFamily});

  /// 获取本地化的主题名称
  String get localizedName => name.tr();
}
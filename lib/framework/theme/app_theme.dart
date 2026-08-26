// 应用主题管理
//
// 提供主题切换、强调色选择和主题构建功能。
// 支持亮色/暗色模式与多种强调色方案的组合，共 20 种预设主题。
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'theme_mixin.dart';

/// 应用主题
///
/// 管理主题选项列表和主题构建逻辑。
/// 通过 [ThemeMixin] 复用通用主题构建能力。
class AppTheme with ThemeMixin {
  AppTheme._();

  /// 预设强调色选项列表（10 种颜色）
  static const List<ThemeAccentOption> accentOptions = [
    ThemeAccentOption('app_accent_indigo', Color(0xFF5A5FD6)),
    ThemeAccentOption('app_accent_aurora', Color(0xFF2F7EF7)),
    ThemeAccentOption('app_accent_teal', Color(0xFF0FA090)),
    ThemeAccentOption('app_accent_emerald', Color(0xFF0E9E72)),
    ThemeAccentOption('app_accent_rose', Color(0xFFD85A8A)),
    ThemeAccentOption('app_accent_coral', Color(0xFFE66A4E)),
    ThemeAccentOption('app_accent_amber', Color(0xFFD28A10)),
    ThemeAccentOption('app_accent_violet', Color(0xFF7250D4)),
    ThemeAccentOption('app_accent_cyan', Color(0xFF1598C8)),
    ThemeAccentOption('app_accent_graphite', Color(0xFF5B6472)),
  ];

  /// 全部主题选项列表（亮色 + 暗色各 10 种，共 20 种）
  static final List<ThemeOption> themes = [
    for (final accent in accentOptions)
      ThemeOption(
        accent.name,
        accent.color,
        Brightness.light,
        _gradientFor(Brightness.light, accent.color),
      ),
    for (final accent in accentOptions)
      ThemeOption(
        accent.name,
        accent.color,
        Brightness.dark,
        _gradientFor(Brightness.dark, accent.color),
      ),
  ];

  /// 固定字体：JetBrainsMono + NotoSansSC 回退
  static const String kFontFamily = 'JetBrainsMono';
  static const List<String> kFontFamilyFallback = ['NotoSansSC'];

  /// 根据主题索引获取 [ThemeData]
  ///
  /// [index] 主题索引，对应 [themes] 列表中的位置
  /// [overrideFontFamily] 可选的字体覆盖（默认 JetBrainsMono）
  ///
  /// 索引越界时默认使用第 0 个主题。
  static ThemeData getTheme({int? index, String? overrideFontFamily}) {
    final idx = (index == null || index < 0 || index >= themes.length)
        ? 0
        : index;
    final t = themes[idx];
    return ThemeMixin.buildTheme(
      brightness: t.brightness,
      primaryColor: t.color,
      gradient: t.gradient,
      fontFamily: overrideFontFamily ?? t.fontFamily ?? kFontFamily,
      fontFamilyFallback: kFontFamilyFallback,
    );
  }

  /// 根据亮暗模式和强调色索引获取 [ThemeData]
  ///
  /// [brightness] 亮色或暗色模式
  /// [accentIndex] 强调色索引，对应 [accentOptions] 列表
  /// [overrideFontFamily] 可选的字体覆盖
  static ThemeData getThemeByModeAndAccent({
    required Brightness brightness,
    required int accentIndex,
    String? overrideFontFamily,
  }) {
    final accent = accentOptions[_safeAccentIndex(accentIndex)];
    return ThemeMixin.buildTheme(
      brightness: brightness,
      primaryColor: accent.color,
      gradient: _gradientFor(brightness, accent.color),
      fontFamily: overrideFontFamily ?? kFontFamily,
      fontFamilyFallback: kFontFamilyFallback,
    );
  }

  /// 计算兼容旧版的主题索引
  ///
  /// [brightness] 亮色或暗色模式
  /// [accentIndex] 强调色索引
  ///
  /// 返回在 [themes] 列表中的位置：
  /// 亮色模式返回 accentIndex，暗色模式返回 accentOptions.length + accentIndex。
  static int compatibilityThemeIndex({
    required Brightness brightness,
    required int accentIndex,
  }) {
    final safeAccent = _safeAccentIndex(accentIndex);
    if (brightness == Brightness.light) return safeAccent;
    return accentOptions.length + safeAccent;
  }

  /// 安全获取强调色索引
  ///
  /// [index] 原始索引，越界时返回 0。
  static int _safeAccentIndex(int index) {
    return index < 0 || index >= accentOptions.length ? 0 : index;
  }

  /// 根据亮暗模式和强调色生成背景渐变
  ///
  /// [brightness] 亮色或暗色模式
  /// [accent] 强调色
  ///
  /// 暗色模式生成深色渐变，亮色模式生成浅色渐变。
  static LinearGradient _gradientFor(Brightness brightness, Color accent) {
    final hsl = HSLColor.fromColor(accent);
    if (brightness == Brightness.dark) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          hsl.withLightness(0.075).withSaturation(0.2).toColor(),
          hsl.withLightness(0.13).withSaturation(0.3).toColor(),
        ],
      );
    }

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        hsl.withLightness(0.975).withSaturation(0.16).toColor(),
        hsl.withLightness(0.925).withSaturation(0.24).toColor(),
      ],
    );
  }
}

/// 主题强调色选项
///
/// 包含强调色的本地化名称和颜色值。
class ThemeAccentOption {
  /// 本地化名称 key
  final String name;

  /// 强调色颜色值
  final Color color;

  const ThemeAccentOption(this.name, this.color);

  /// 获取本地化后的显示名称
  String get localizedName => name.tr();
}

/// 主题选项
///
/// 包含主题的名称、颜色、亮度模式、渐变背景和可选字体。
class ThemeOption {
  /// 本地化名称 key
  final String name;

  /// 主题主色
  final Color? color;

  /// 亮度模式（亮色/暗色）
  final Brightness brightness;

  /// 背景渐变
  final LinearGradient gradient;

  /// 可选的自定义字体
  final String? fontFamily;

  const ThemeOption(
    this.name,
    this.color,
    this.brightness,
    this.gradient, {
    this.fontFamily,
  });

  /// 获取本地化后的显示名称
  String get localizedName => name.tr();
}

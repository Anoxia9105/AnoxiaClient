// 应用主题管理
//
// 提供主题切换、强调色选择和主题构建功能。
// 支持亮色/暗色模式与多种强调色方案的组合，16 预设 + 自定义色。
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'theme_mixin.dart';

/// 强调色分组
enum AccentCategory {
  vibrant('accent_category_vibrant'),
  morandi('accent_category_morandi'),
  deep('accent_category_deep'),
  earth('accent_category_earth');

  const AccentCategory(this.labelKey);
  final String labelKey;
  String get localizedLabel => labelKey.tr();
}

/// 应用主题
///
/// 管理主题选项列表和主题构建逻辑。
/// 通过 [ThemeMixin] 复用通用主题构建能力。
class AppTheme with ThemeMixin {
  AppTheme._();

  /// 预设强调色选项列表（16 种，莫兰迪柔和系 + 微调旧色）
  ///
  /// 旧 10 色已做饱和度/明度微调（更柔和、与 M3 fromSeed 更协调），
  /// 新增 6 色补齐中性/大地/深邃区间，整体按 hue 分组。
  static const List<ThemeAccentOption> accentOptions = [
    // 经典活力（微调后更柔和）
    ThemeAccentOption('app_accent_indigo', Color(0xFF5E66D0), AccentCategory.vibrant),
    ThemeAccentOption('app_accent_aurora', Color(0xFF4A8FE7), AccentCategory.vibrant),
    ThemeAccentOption('app_accent_teal', Color(0xFF2AA596), AccentCategory.vibrant),
    ThemeAccentOption('app_accent_emerald', Color(0xFF2FA87A), AccentCategory.vibrant),
    ThemeAccentOption('app_accent_rose', Color(0xFFCE7A96), AccentCategory.vibrant),
    ThemeAccentOption('app_accent_coral', Color(0xFFE07A5F), AccentCategory.vibrant),
    // 柔和莫兰迪新增
    ThemeAccentOption('app_accent_mist', Color(0xFF7A8EB5), AccentCategory.morandi),
    ThemeAccentOption('app_accent_sage', Color(0xFF8CA89A), AccentCategory.morandi),
    ThemeAccentOption('app_accent_mauve', Color(0xFFA48EB5), AccentCategory.morandi),
    ThemeAccentOption('app_accent_oat', Color(0xFFB8A99A), AccentCategory.morandi),
    // 深邃夜色
    ThemeAccentOption('app_accent_violet', Color(0xFF7D6BCF), AccentCategory.deep),
    ThemeAccentOption('app_accent_midnight', Color(0xFF3E5A73), AccentCategory.deep),
    ThemeAccentOption('app_accent_graphite', Color(0xFF6B7787), AccentCategory.deep),
    // 温暖大地 & 优化旧色
    ThemeAccentOption('app_accent_amber', Color(0xFFC9A13A), AccentCategory.earth),
    ThemeAccentOption('app_accent_cyan', Color(0xFF4A9CC6), AccentCategory.earth),
    ThemeAccentOption('app_accent_sand', Color(0xFFC2A68A), AccentCategory.earth),
  ];

  /// 全部主题选项列表（亮色 + 暗色各 N 种）
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

  /// 按分组获取强调色索引
  static Map<AccentCategory, List<int>> get groupedAccentIndices {
    final map = <AccentCategory, List<int>>{
      for (final c in AccentCategory.values) c: [],
    };
    for (var i = 0; i < accentOptions.length; i++) {
      map[accentOptions[i].category]!.add(i);
    }
    return map;
  }

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
  /// 莫兰迪系与大地色降低饱和度、提升层次感，避免高饱和背景刺眼。
  static LinearGradient _gradientFor(Brightness brightness, Color accent) {
    final hsl = HSLColor.fromColor(accent);
    // 按色相/饱和度自适应：高饱和色降饱，低饱和莫兰迪保留通透
    final baseSaturation = hsl.saturation;
    final isMuted = baseSaturation < 0.42;
    if (brightness == Brightness.dark) {
      final s1 = isMuted ? 0.18 : 0.22;
      final s2 = isMuted ? 0.24 : 0.32;
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          hsl.withLightness(0.065).withSaturation(s1).toColor(),
          hsl.withLightness(0.115).withSaturation(s2).toColor(),
        ],
      );
    }
    final s1 = isMuted ? 0.14 : 0.18;
    final s2 = isMuted ? 0.20 : 0.26;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        hsl.withLightness(0.978).withSaturation(s1).toColor(),
        hsl.withLightness(0.935).withSaturation(s2).toColor(),
      ],
    );
  }

  /// 自定义色构建主题（用于取色器）
  static ThemeData getThemeForCustomColor({
    required Brightness brightness,
    required Color color,
    String? overrideFontFamily,
  }) {
    return ThemeMixin.buildTheme(
      brightness: brightness,
      primaryColor: color,
      gradient: _gradientFor(brightness, color),
      fontFamily: overrideFontFamily ?? kFontFamily,
      fontFamilyFallback: kFontFamilyFallback,
    );
  }
}

/// 主题强调色选项
///
/// 包含强调色的本地化名称、颜色值与分组。
class ThemeAccentOption {
  /// 本地化名称 key
  final String name;

  /// 强调色颜色值
  final Color color;

  /// 所属分组
  final AccentCategory category;

  const ThemeAccentOption(this.name, this.color, [this.category = AccentCategory.vibrant]);

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

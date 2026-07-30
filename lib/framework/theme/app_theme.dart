import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'theme_mixin.dart';

class AppTheme with ThemeMixin {
  AppTheme._();

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

  static ThemeData getTheme({int? index, String? overrideFontFamily}) {
    final idx = (index == null || index < 0 || index >= themes.length)
        ? 0
        : index;
    final t = themes[idx];
    return ThemeMixin.buildTheme(
      brightness: t.brightness,
      primaryColor: t.color,
      gradient: t.gradient,
      fontFamily: overrideFontFamily ?? t.fontFamily,
    );
  }

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
      fontFamily: overrideFontFamily,
    );
  }

  static int compatibilityThemeIndex({
    required Brightness brightness,
    required int accentIndex,
  }) {
    final safeAccent = _safeAccentIndex(accentIndex);
    if (brightness == Brightness.light) return safeAccent;
    return accentOptions.length + safeAccent;
  }

  static int _safeAccentIndex(int index) {
    return index < 0 || index >= accentOptions.length ? 0 : index;
  }

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

class ThemeAccentOption {
  final String name;
  final Color color;

  const ThemeAccentOption(this.name, this.color);

  String get localizedName => name.tr();
}

class ThemeOption {
  final String name;
  final Color? color;
  final Brightness brightness;
  final LinearGradient gradient;
  final String? fontFamily;

  const ThemeOption(
    this.name,
    this.color,
    this.brightness,
    this.gradient, {
    this.fontFamily,
  });

  String get localizedName => name.tr();
}

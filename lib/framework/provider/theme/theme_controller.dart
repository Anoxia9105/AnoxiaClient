import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../gen/fonts.gen.dart';
import '../../../common/utils/sp_util.dart';
import '../../theme/app_theme.dart';

part 'theme_controller.g.dart';

/// 支持的全局字体 key
class AppFontKeys {
  AppFontKeys._();

  static const String roboto = 'roboto';
  static const String inter = 'inter';
  static const String openSans = 'open_sans';
  static const String lato = 'lato';
  static const String montserrat = 'montserrat';
  static const String poppins = 'poppins';
  static const String sourceSans3 = 'source_sans_3';
  static const String nunito = 'nunito';
  static const String merriweather = 'merriweather';
  static const String notoSansSc = 'noto_sans_sc';
  static const String notoSansJp = 'noto_sans_jp';
  static const String harmonyOS = 'harmony_os';
}

/// 全局字体配置（含显示名 key）
class AppFontOption {
  final String key;
  final String labelKey;

  const AppFontOption({required this.key, required this.labelKey});
}

const List<AppFontOption> appFontOptions = [
  AppFontOption(key: AppFontKeys.roboto, labelKey: 'settings_font_roboto'),
  AppFontOption(key: AppFontKeys.inter, labelKey: 'settings_font_inter'),
  AppFontOption(key: AppFontKeys.openSans, labelKey: 'settings_font_open_sans'),
  AppFontOption(key: AppFontKeys.lato, labelKey: 'settings_font_lato'),
  AppFontOption(
    key: AppFontKeys.montserrat,
    labelKey: 'settings_font_montserrat',
  ),
  AppFontOption(key: AppFontKeys.poppins, labelKey: 'settings_font_poppins'),
  AppFontOption(
    key: AppFontKeys.sourceSans3,
    labelKey: 'settings_font_source_sans_3',
  ),
  AppFontOption(key: AppFontKeys.nunito, labelKey: 'settings_font_nunito'),
  AppFontOption(
    key: AppFontKeys.merriweather,
    labelKey: 'settings_font_merriweather',
  ),
  AppFontOption(
    key: AppFontKeys.notoSansSc,
    labelKey: 'settings_font_noto_sans_sc',
  ),
  AppFontOption(
    key: AppFontKeys.notoSansJp,
    labelKey: 'settings_font_noto_sans_jp',
  ),
  AppFontOption(
    key: AppFontKeys.harmonyOS,
    labelKey: 'settings_font_harmony_os',
  ),
];

/// 全局字体状态（持久化）
class AppFontController extends StateNotifier<String> {
  static const String _storageKey = 'app_font_key';

  AppFontController() : super(_load());

  static String _load() {
    final saved = SPUtil.instance.get(
      _storageKey,
      defValue: AppFontKeys.roboto,
    );

    if (saved != null && appFontOptions.any((option) => option.key == saved)) {
      return saved;
    }
    return AppFontKeys.roboto;
  }

  void setFont(String fontKey) {
    if (state == fontKey) return;
    state = fontKey;
    SPUtil.instance.set(_storageKey, fontKey);
  }
}

final appFontProvider = StateNotifierProvider<AppFontController, String>((ref) {
  return AppFontController();
});

class ThemeModeController extends StateNotifier<Brightness> {
  static const String _storageKey = 'theme_brightness';

  ThemeModeController() : super(_load());

  static Brightness _load() {
    final saved = SPUtil.instance.get(_storageKey, defValue: 'light');
    return saved == 'dark' ? Brightness.dark : Brightness.light;
  }

  void setMode(Brightness brightness) {
    if (state == brightness) return;
    state = brightness;
    SPUtil.instance.set(
      _storageKey,
      brightness == Brightness.dark ? 'dark' : 'light',
    );
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, Brightness>(
      (ref) => ThemeModeController(),
    );

class ThemeAccentController extends StateNotifier<int> {
  static const String _storageKey = 'theme_accent_index';

  ThemeAccentController() : super(_load());

  static int _load() {
    final saved = SPUtil.instance.getInt(_storageKey, defValue: 0) ?? 0;
    return saved < 0 || saved >= AppTheme.accentOptions.length ? 0 : saved;
  }

  void setAccent(int index) {
    final safeIndex = index < 0 || index >= AppTheme.accentOptions.length
        ? 0
        : index;
    if (state == safeIndex) return;
    state = safeIndex;
    SPUtil.instance.setInt(_storageKey, safeIndex);
  }
}

final themeAccentProvider = StateNotifierProvider<ThemeAccentController, int>(
  (ref) => ThemeAccentController(),
);

/// 主题索引 Provider
///
/// 持久化存储用户选择的主题索引（0=浅色，1=深色等）。
@Riverpod(keepAlive: true)
class ThemeIndex extends _$ThemeIndex {
  @override
  int build() {
    final themeIndex = SPUtil.instance.getInt('theme_index', defValue: 0);
    return themeIndex ?? 0;
  }

  /// 设置主题
  ///
  /// [index] 主题索引，对应 [AppTheme.getTheme] 的参数
  void setTheme(int index) {
    state = index;
    SPUtil.instance.setInt('theme_index', index);
  }
}

/// 应用主题 Provider
///
/// 根据 [ThemeIndex] 动态生成对应的 ThemeData
@riverpod
ThemeData appTheme(Ref ref) {
  final brightness = ref.watch(themeModeProvider);
  final accentIndex = ref.watch(themeAccentProvider);
  final fontKey = ref.watch(appFontProvider);
  ThemeData baseTheme = AppTheme.getThemeByModeAndAccent(
    brightness: brightness,
    accentIndex: accentIndex,
  );

  // Web 端强制系统字体：字体选项均来自 google_fonts（运行时从 Google CDN
  // 拉取，国内基本不可达，选择后实际无声回退），且自定义 CJK 字体在
  // Safari（CanvasKit/skwasm）下栅格化成本高。Web 直接返回 baseTheme，
  // 字体设置入口已在设置页隐藏，这里不再套任何 TextTheme。
  if (kIsWeb) {
    return baseTheme;
  }

  final textTheme = _buildTextTheme(fontKey, baseTheme.textTheme);
  final primaryTextTheme = _buildTextTheme(fontKey, baseTheme.primaryTextTheme);

  return baseTheme.copyWith(
    textTheme: textTheme,
    primaryTextTheme: primaryTextTheme,
  );
}

TextTheme _buildTextTheme(String fontKey, TextTheme baseTextTheme) {
  switch (fontKey) {
    case AppFontKeys.inter:
      return GoogleFonts.interTextTheme(baseTextTheme);
    case AppFontKeys.openSans:
      return GoogleFonts.openSansTextTheme(baseTextTheme);
    case AppFontKeys.lato:
      return GoogleFonts.latoTextTheme(baseTextTheme);
    case AppFontKeys.montserrat:
      return GoogleFonts.montserratTextTheme(baseTextTheme);
    case AppFontKeys.poppins:
      return GoogleFonts.poppinsTextTheme(baseTextTheme);
    case AppFontKeys.sourceSans3:
      return GoogleFonts.sourceSans3TextTheme(baseTextTheme);
    case AppFontKeys.nunito:
      return GoogleFonts.nunitoTextTheme(baseTextTheme);
    case AppFontKeys.merriweather:
      return GoogleFonts.merriweatherTextTheme(baseTextTheme);
    case AppFontKeys.notoSansSc:
      return GoogleFonts.notoSansScTextTheme(baseTextTheme);
    case AppFontKeys.notoSansJp:
      return GoogleFonts.notoSansJpTextTheme(baseTextTheme);
    case AppFontKeys.harmonyOS:
      return baseTextTheme.apply(fontFamily: FontFamily.harmonyOS);
    case AppFontKeys.roboto:
    default:
      return GoogleFonts.robotoTextTheme(baseTextTheme);
  }
}

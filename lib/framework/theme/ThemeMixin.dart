import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'AppColors.dart';

mixin ThemeMixin {
  /// 工具：基于整数 alpha (0.0-1.0 -> 0-255) 返回带透明度的颜色。
  /// 采用 withAlpha(int) 而不是 withOpacity，以规避部分 SDK 的弃用提示。
  static Color colorWithAlpha(Color c, double alpha) {
    assert(alpha >= 0.0 && alpha <= 1.0);
    return c.withAlpha((alpha * 255).round());
  }

  /// 构建 ThemeData：所有组件样式都基于此 colorScheme。
  static ThemeData buildTheme({
    required Brightness brightness,
    required Color? primaryColor,
    required LinearGradient gradient,
    String? fontFamily,
  }) {
    final seed = primaryColor ?? Colors.indigo;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    // -------------------------
    // Button 风格（统一放在 buildTheme 内以便读取 colorScheme）
    // -------------------------

    // OutlinedButton（边框按钮）
    final outlinedButtonTheme = OutlinedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(
              color: colorWithAlpha(colorScheme.onSurface, 0.12),
              width: 1,
            );
          }
          // 正常状态使用 primary
          return BorderSide(color: colorScheme.primary, width: 1);
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorWithAlpha(colorScheme.onSurface, 0.38);
          }
          return colorScheme.primary;
        }),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );

    // TextButton（文本按钮）
    final textButtonTheme = TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorWithAlpha(colorScheme.onSurface, 0.38);
          }
          return colorScheme.primary;
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );

    // FilledButton / ElevatedButton（填充/突起按钮）
    final filledButtonTheme = FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorWithAlpha(colorScheme.onSurface, 0.12);
          }
          return colorScheme.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorWithAlpha(colorScheme.onSurface, 0.38);
          }
          return colorScheme.onPrimary;
        }),
        elevation: WidgetStateProperty.resolveWith<double?>((states) {
          if (states.contains(WidgetState.disabled)) return 0;
          return 4;
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
    );

    // 兼容配置：ElevatedButtonTheme（Material2 兼容）
    final elevatedButtonTheme = ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorWithAlpha(colorScheme.onSurface, 0.12);
          }
          return colorScheme.primary;
        }),
        foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
        elevation: WidgetStateProperty.all(4.0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );

    // IconButton
    final iconButtonTheme = IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorWithAlpha(colorScheme.onSurface, 0.38);
          }
          return colorScheme.onSurface;
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );

    // FloatingActionButton
    final fabTheme = FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 6,
      hoverElevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );

    // -------------------------
    // 表单 / 输入（InputDecoration）主题
    // -------------------------
    final inputDecorationTheme = InputDecorationTheme(
      isDense: true,
      filled: true,
      // fillColor: colorScheme.surfaceContainerHighest,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
      // 表单背景使用 surfaceContainerHighest，适配 M3
      // contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorWithAlpha(colorScheme.onSurface, 0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.25),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      hintStyle: TextStyle(color: colorWithAlpha(colorScheme.onSurface, 0.6)),
      labelStyle: TextStyle(color: colorWithAlpha(colorScheme.onSurface, 0.8)),
    );

    // -------------------------
    // 选择控件（Checkbox/Radio/Switch）主题
    // -------------------------
    final checkboxTheme = CheckboxThemeData(
      side: BorderSide(color: colorWithAlpha(colorScheme.onSurface, 0.12)),
      fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorWithAlpha(colorScheme.onSurface, 0.12);
        }
        if (states.contains(WidgetState.selected)) return colorScheme.primary;
        return colorWithAlpha(colorScheme.onSurface, 0.6);
      }),
      checkColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorWithAlpha(colorScheme.onSurface, 0.38);
        }
        return colorScheme.onPrimary;
      }),
    );

    final radioTheme = RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorWithAlpha(colorScheme.onSurface, 0.12);
        }
        return colorScheme.primary;
      }),
    );

    final switchTheme = SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorWithAlpha(colorScheme.onSurface, 0.12);
        }
        return colorScheme.primary;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorWithAlpha(colorScheme.onSurface, 0.06);
        }
        return colorWithAlpha(colorScheme.primary, 0.24);
      }),
    );

    // -------------------------
    // Slider 主题
    // -------------------------
    final sliderTheme = SliderThemeData(
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorWithAlpha(colorScheme.onSurface, 0.12),
      thumbColor: colorScheme.primary,
      overlayColor: colorWithAlpha(colorScheme.primary, 0.12),
      valueIndicatorColor: colorScheme.primary,
    );

    // -------------------------
    // Chip / Card / Dialog / Tooltip / PopupMenu 主题
    // -------------------------
    final chipTheme =
        ChipThemeData.fromDefaults(
          secondaryColor: colorScheme.primary,
          labelStyle: TextStyle(color: colorScheme.onSurface),
          brightness: brightness,
        ).copyWith(
          backgroundColor: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        );

    final cardTheme = CardThemeData(
      elevation: 0,
      // color: brightness == Brightness.light ? Colors.white : null,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          width: 1,
          color: colorWithAlpha(colorScheme.onSurface, 0.1),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(8),
    );

    final dialogTheme = DialogThemeData(
      // backgroundColor: brightness == Brightness.light ? Colors.white : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        color: colorWithAlpha(colorScheme.onSurface, 0.9),
      ),
    );

    final popupMenuTheme = PopupMenuThemeData(
      color: colorScheme.surface,
      textStyle: TextStyle(color: colorScheme.onSurface),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    final tooltipTheme = TooltipThemeData(
      decoration: BoxDecoration(
        color: colorWithAlpha(colorScheme.onSurface, 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: TextStyle(color: colorScheme.onPrimary),
      waitDuration: const Duration(milliseconds: 500),
    );

    // -------------------------
    // AppBar / BottomNavigationBar / TabBar / Progress / DataTable / Divider
    // -------------------------
    final appBarTheme = AppBarTheme(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            brightness == Brightness.dark ? Brightness.dark : Brightness.light,
      ),
    );

    //底部导航栏
    final bottomNavigationBarTheme = BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorWithAlpha(colorScheme.onSurface, 0.6),
      selectedLabelStyle: const TextStyle(fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    );

    //选项切换
    final tabBarTheme = TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorWithAlpha(colorScheme.onSurface, 0.7),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 14),
    );

    // 加载状态配置
    final progressIndicatorTheme = ProgressIndicatorThemeData(
      color: colorScheme.primary, // Windows 经典蓝色
      linearTrackColor: colorScheme.onPrimary, // 轨道颜色（主要用于线性进度条，圆形的通常透明）
      circularTrackColor: Colors.transparent,
      strokeWidth: 4.0, // 圆环的粗细
      refreshBackgroundColor: colorScheme.primary, // 下拉刷新时的背景色
      strokeCap: StrokeCap.round,
      borderRadius: BorderRadius.circular(4),
      constraints: BoxConstraints.tight(Size(25, 25)),
    );

    //表格
    final dataTableTheme = DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(
        colorScheme.surfaceContainerHighest,
      ),
      headingTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      dataRowColor: WidgetStateProperty.all(colorScheme.surface),
      dataTextStyle: TextStyle(
        color: colorWithAlpha(colorScheme.onSurface, 0.9),
      ),
    );

    //分割线
    final dividerTheme = DividerThemeData(
      thickness: 1,
      color: colorWithAlpha(colorScheme.onSurface, 0.06),
      space: 1,
    );

    final listTileTheme = ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    // -------------------------
    // 最终 ThemeData 组装并返回
    // -------------------------
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily ?? 'HarmonyOS',
      brightness: brightness,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      primaryColor: primaryColor,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: appBarTheme,
      extensions: <ThemeExtension<dynamic>>[
        AppColors(scaffoldGradient: gradient),
      ],

      // 组件级主题注入
      bottomNavigationBarTheme: bottomNavigationBarTheme,
      tabBarTheme: tabBarTheme,
      outlinedButtonTheme: outlinedButtonTheme,
      textButtonTheme: textButtonTheme,
      filledButtonTheme: filledButtonTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      iconButtonTheme: iconButtonTheme,
      floatingActionButtonTheme: fabTheme,
      inputDecorationTheme: inputDecorationTheme,
      checkboxTheme: checkboxTheme,
      radioTheme: radioTheme,
      switchTheme: switchTheme,
      sliderTheme: sliderTheme,
      chipTheme: chipTheme,
      cardTheme: cardTheme,
      dialogTheme: dialogTheme,
      popupMenuTheme: popupMenuTheme,
      tooltipTheme: tooltipTheme,
      progressIndicatorTheme: progressIndicatorTheme,
      dataTableTheme: dataTableTheme,
      dividerTheme: dividerTheme,
      listTileTheme: listTileTheme,
    );
  }
}

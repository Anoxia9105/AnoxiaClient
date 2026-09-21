import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'package:anoxia/common/utils/motion_utils.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

mixin ThemeMixin {
  /// 工具：基于整数 alpha (0.0-1.0 -> 0-255) 返回带透明度的颜色。
  /// 采用 withAlpha(int) 而不是 withOpacity，以规避部分 SDK 的弃用提示。
  static Color colorWithAlpha(Color c, double alpha) {
    assert(alpha >= 0.0 && alpha <= 1.0);
    return c.withAlpha((alpha * 255).round());
  }

  /// 语义色令牌：根据亮/暗模式返回一组高对比度的成功/警告/危险/信息色。
  ///
  /// 亮色使用深色调（白底上可读），暗色使用浅色调（深底上可读）。
  /// 危险色直接复用 colorScheme.error，保证与表单错误、删除操作一致。
  static ({Color success, Color warning, Color danger, Color info, Color onGradient})
      _buildSemanticColors(ColorScheme colorScheme, Brightness brightness) {
    if (brightness == Brightness.dark) {
      return (
        success: const Color(0xFF81C784),
        warning: const Color(0xFFFFB74D),
        danger: colorScheme.error,
        info: const Color(0xFFB0BEC5),
        onGradient: Colors.white,
      );
    }
    return (
      success: const Color(0xFF2E7D32),
      warning: const Color(0xFF8A5A00),
      danger: colorScheme.error,
      info: const Color(0xFF455A64),
      onGradient: Colors.white,
    );
  }

  /// 构建 ThemeData：所有组件样式都基于此 colorScheme。
  /// [fontFamily] 主字体（JetBrainsMono），[fontFamilyFallback] CJK 回退（NotoSansSC）
  static ThemeData buildTheme({
    required Brightness brightness,
    required Color? primaryColor,
    required LinearGradient gradient,
    String? fontFamily,
    List<String>? fontFamilyFallback,
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
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.sm)),
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
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.sm)),
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
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.sm)),
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
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.sm)),
        ),
      ),
    );

    // IconButton
    final iconButtonTheme = IconButtonThemeData(
      style: ButtonStyle(
        mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorWithAlpha(colorScheme.onSurface, 0.38);
          }
          return colorScheme.onSurface;
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.sm)),
        ),
      ),
    );

    // FloatingActionButton
    final fabTheme = FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 6,
      hoverElevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.xl)),
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
        borderRadius: BorderRadius.circular(RadiusToken.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RadiusToken.md),
        borderSide: BorderSide(
          color: colorWithAlpha(colorScheme.onSurface, 0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RadiusToken.md),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.25),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RadiusToken.md),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.md)),
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
        borderRadius: BorderRadius.circular(RadiusToken.md),
      ),
      margin: const EdgeInsets.all(8),
    );

    final dialogTheme = DialogThemeData(
      // backgroundColor: brightness == Brightness.light ? Colors.white : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.md)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.md)),
    );

    final tooltipTheme = TooltipThemeData(
      decoration: BoxDecoration(
        color: colorWithAlpha(colorScheme.onSurface, 0.9),
        borderRadius: BorderRadius.circular(RadiusToken.sm),
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
      centerTitle: true,
      backgroundColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: brightness == Brightness.dark
            ? Brightness.dark
            : Brightness.light,
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
      borderRadius: BorderRadius.circular(RadiusToken.sm),
      constraints: BoxConstraints.tight(const Size(25, 25)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.md)),
    );

    // -------------------------
    // 页面切换动画：统一从右向左滑入（iOS 风格推入）
    // 替换各平台默认的淡入淡出/缩放（Android Zoom、桌面 FadeUpwards 等），
    // 覆盖所有 MaterialPageRoute——go_router 类型路由与直接 Navigator.push 全部生效。
    // 减少动效开启时（MediaQuery.disableAnimations）直接返回子节点，无过渡。
    // -------------------------
    final pageTransitionsTheme = PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: const ReduceMotionPageTransitionsBuilder(),
      },
    );

    // -------------------------
    // 最终 ThemeData 组装并返回
    // -------------------------
    // 语义色令牌：亮色用深色调、暗色用浅色调，保证对比度
    final semanticColors = _buildSemanticColors(colorScheme, brightness);

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      brightness: brightness,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      primaryColor: primaryColor,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: appBarTheme,
      extensions: <ThemeExtension<dynamic>>[
        AppColors(
          scaffoldGradient: gradient,
          success: semanticColors.success,
          warning: semanticColors.warning,
          danger: semanticColors.danger,
          info: semanticColors.info,
          onGradient: semanticColors.onGradient,
        ),
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
      pageTransitionsTheme: pageTransitionsTheme,
    );
  }
}

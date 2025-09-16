import 'package:flutter/material.dart';
import 'package:notepadclient/shared/theme/AppColors.dart';

/// AppTheme
/// - 提供若干预定义 ThemeData 实例，便于在应用中统一管理主题。
/// - 使用示例：Theme.of(context) 在需要时配合 Provider/Bloc/SharedPreferences 做动态切换。
class AppTheme {
  AppTheme._(); // 私有构造，禁止实例化

  static final List<ThemeData> _themeList = [
    // light 1 - 经典蓝
    ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.indigo,
      primaryColor: Colors.indigo,
      colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo)
          .copyWith(secondary: Colors.blueAccent),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      ),
      cardTheme: CardTheme(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        elevation: 2,
      ),
      iconTheme: const IconThemeData(size: 20),
      extensions: <ThemeExtension<dynamic>>[
        const AppColors(
          scaffoldGradient: LinearGradient(
            colors: [Color(0xFFE6E6E9), Color(0xFFEAE6DB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    ),

    // light 2 - 绿色企业风
    ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.green,
      colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green)
          .copyWith(secondary: Colors.greenAccent),
      scaffoldBackgroundColor: const Color(0xFFF7F9FB),
      appBarTheme: const AppBarTheme(
        elevation: 1,
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.green),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      ),
      cardTheme: CardTheme(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        elevation: 1,
      ),
      iconTheme: const IconThemeData(size: 20),
    ),

    // dark 1 - 深色（沉稳蓝灰）
    ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.indigo,
      colorScheme: ColorScheme.dark(primary: Colors.indigo, secondary: Colors.indigoAccent),
      scaffoldBackgroundColor: const Color(0xFF0F1724),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Color(0xFF111827),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.indigo,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F2937),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF111827),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        elevation: 2,
      ),
      iconTheme: const IconThemeData(size: 20),
    ),

    // dark 2 - 高对比深色（用于更强视觉区分）
    ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.teal,
      colorScheme: ColorScheme.dark(primary: Colors.teal, secondary: Colors.tealAccent),
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      appBarTheme: const AppBarTheme(
        elevation: 1,
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Color(0xFF06202A),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.teal,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F1724),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF071426),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        elevation: 1,
      ),
      iconTheme: const IconThemeData(size: 20),
    ),
  ];

  /// 主题数量
  static int get themeCount => _themeList.length;

  /// 根据 index 获取 ThemeData，index 为 null 或越界时返回默认主题（index 0）
  static ThemeData getTheme({int? index}) {
    if (index == null) return _themeList[0];
    if (index < 0 || index >= _themeList.length) return _themeList[0];
    return _themeList[index];
  }

  /// 返回主题名称（便于在 UI 展示）
  static String getThemeName(int index) {
    switch (index) {
      case 0:
        return 'Light - 蓝色';
      case 1:
        return 'Light - 绿色';
      case 2:
        return 'Dark - 蓝灰';
      case 3:
        return 'Dark - 高对比';
      default:
        return 'Default';
    }
  }

  /// 在给定的当前 index 下，返回下一个 index（循环）
  static int nextThemeIndex(int currentIndex) {
    if (currentIndex < 0 || currentIndex >= _themeList.length) return 0;
    return (currentIndex + 1) % _themeList.length;
  }
}

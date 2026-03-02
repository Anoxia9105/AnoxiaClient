import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'ThemeMixin.dart';

class AppTheme with ThemeMixin {
  AppTheme._(); // 禁止实例化

  /// 主题元数据 - 精心设计的现代化配色方案
  static final List<ThemeOption> themes = [
    // ==================== 亮色主题系列 ====================
    ThemeOption(
      'app_light_themes1',
      const Color(0xFF6366F1), // Indigo 500 - 经典靛蓝
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
      ),
    ),
    ThemeOption(
      'app_light_themes2',
      const Color(0xFF10B981), // Emerald 500 - 翡翠绿
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
      ),
    ),
    ThemeOption(
      'app_light_themes3',
      const Color(0xFFF472B6), // Pink 400 - 樱花粉
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF5F7), Color(0xFFFFF0F5)],
      ),
    ),
    ThemeOption(
      'app_light_themes4',
      const Color(0xFF14B8A6), // Teal 500 - 薄荷青
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF0FDFA), Color(0xFFCCFBF1)],
      ),
    ),
    ThemeOption(
      'app_light_themes5',
      const Color(0xFF6B7280), // Gray 500 - 素雅灰
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
      ),
    ),
    ThemeOption(
      'app_light_themes6',
      const Color(0xFFF59E0B), // Amber 500 - 暖阳橙
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
      ),
    ),
    ThemeOption(
      'app_light_themes7',
      const Color(0xFF8B5CF6), // Violet 500 - 薰衣草紫
      Brightness.light,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
      ),
    ),
    
    // ==================== 暗色主题系列 ====================
    ThemeOption(
      'app_dark_themes8',
      const Color(0xFF3B82F6), // Blue 500 - 星空蓝
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      ),
    ),
    ThemeOption(
      'app_dark_themes9',
      const Color(0xFFA855F7), // Purple 500 - 霓虹紫
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
      ),
    ),
    ThemeOption(
      'app_dark_themes10',
      const Color(0xFF6EE7B7), // Emerald 300 - 森林雾
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF134E4A), Color(0xFF115E59)],
      ),
    ),
    ThemeOption(
      'app_dark_themes11',
      const Color(0xFFFBBF24), // Amber 400 - 鎏金岁月
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF451A03), Color(0xFF78350F)],
      ),
    ),
    ThemeOption(
      'app_dark_themes12',
      const Color(0xFFF87171), // Red 400 - 熔岩之心
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2B0F0F), Color(0xFF450A0A)],
      ),
    ),
    ThemeOption(
      'app_dark_themes13',
      const Color(0xFF0EA5E9), // Sky 500 - 深海之蓝
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0C4A6E), Color(0xFF075985)],
      ),
    ),
    ThemeOption(
      'app_dark_themes14',
      const Color(0xFFD97706), // Amber 600 - 可可大地
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF271C19), Color(0xFF451A03)],
      ),
    ),
    ThemeOption(
      'app_dark_themes15',
      const Color(0xFFC084FC), // Purple 400 - 紫晶星云
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E1065), Color(0xFF4C1D95)],
      ),
    ),
    ThemeOption(
      'app_dark_themes16',
      const Color(0xFF22C55E), // Green 500 - 矩阵代码
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF022C22), Color(0xFF064E3B)],
      ),
    ),
    ThemeOption(
      'app_dark_themes17',
      const Color(0xFFF97316), // Orange 500 - 落日余晖
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF431407), Color(0xFF7C2D12)],
      ),
    ),
    ThemeOption(
      'app_dark_themes18',
      const Color(0xFF67E8F9), // Cyan 300 - 冬之冰川
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF164E63), Color(0xFF0E7490)],
      ),
    ),
    ThemeOption(
      'app_dark_themes19',
      const Color(0xFF9CA3AF), // Gray 400 - 水墨石墨
      Brightness.dark,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF171717), Color(0xFF262626)],
      ),
    ),
    // ThemeOption(
    //   '测试1',
    //   const Color(0xFF2B2B2B),
    //   Brightness.light,
    //   const LinearGradient(
    //     begin: Alignment.topLeft,
    //     end: Alignment.topRight,
    //     colors: [Color(0xFFC9D6FF), Color(0xFFE2E2E2)],
    //   ),
    // ),
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

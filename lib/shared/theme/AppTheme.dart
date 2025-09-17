import 'package:flutter/material.dart';
import 'package:notepadclient/shared/theme/AppColors.dart';
import 'package:notepadclient/shared/theme/MixinTheme.dart';

/// AppTheme
/// - 提供一个包含20款精心设计主题的豪华库。
/// - 使用示例：Theme.of(context) 在需要时配合 Provider/Bloc/SharedPreferences 做动态切换。
class AppTheme with MixinTheme {
  AppTheme._(); // 私有构造，禁止实例化

  static const List<String> themeNames = [
    // Light
    '经典蓝',
    '企业绿',
    '初樱',
    '薄荷',
    '浅纸白',
    '暖阳',
    '薰衣草',
    // Dark
    '静谧星空',
    '霓虹之夜',
    '林间薄雾',
    '鎏金岁月',
    '熔岩之心',
    '深海',
    '可可大地',
    '紫晶星云',
    '矩阵代码',
    '落日晚霞',
    '凛冬冰川',
    '水墨石墨',
  ];

  /// 主题列表
  static final List<ThemeData> _themeList = [
    //==========================================================================
    // Light Themes (7款)
    //==========================================================================

    // 0: Light - 经典蓝
    MixinTheme.buildTheme(
      brightness: Brightness.light,
      primaryColor: Colors.indigo,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE6E6E9), Color(0xFFEAE6DB)],
      ),
    ),
    // 1: Light - 企业绿
    MixinTheme.buildTheme(
      brightness: Brightness.light,
      primaryColor: Colors.green.shade700,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFDEE4EA), Color(0xFFC3CBD6)],
      ),
    ),
    // 2: Light - 初樱 (新增)
    MixinTheme.buildTheme(
      brightness: Brightness.light,
      primaryColor: Colors.pink[300],
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF0F5), Color(0xFFFEF9F3)],
      ),
    ),

    // 3: Light - 薄荷 (新增)
    MixinTheme.buildTheme(
      brightness: Brightness.light,
      primaryColor: Colors.teal[400],
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF0FFFF), Color(0xFFF5FFFA)],
      ),
    ),

    // 4: Light - 纸白 (新增)
    MixinTheme.buildTheme(
      brightness: Brightness.light,
      primaryColor: Colors.blueGrey,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
      ),
    ),

    // 5: Light - 暖阳 (新增)
    MixinTheme.buildTheme(
      brightness: Brightness.light,
      primaryColor: Colors.orange[700],
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFDE7), Color(0xFFFFFFFF)],
      ),
    ),

    // 6: Light - 薰衣草 (新增)
    MixinTheme.buildTheme(
      brightness: Brightness.light,
      primaryColor: Colors.deepPurple[300],
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF3E5F5), Color(0xFFFFFFFF)],
      ),
    ),
    //==========================================================================
    // Dark Themes (13款)
    //==========================================================================

    // 7: Dark - 静谧星空
    MixinTheme.buildTheme(
      brightness: Brightness.dark,
      primaryColor: Colors.blue[200],
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D0221), Color(0xFF241744)],
      ),
    ),
    // 8: Dark - 霓虹之夜
    MixinTheme.buildTheme(
      brightness: Brightness.dark,
      primaryColor: Colors.pinkAccent[200],
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF000428), Color(0xFF004e92)],
      ),
    ),
    // 10: Dark - 林间薄雾
    MixinTheme.buildTheme(
      brightness: Brightness.dark,
      primaryColor: Colors.greenAccent[100],
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF101D21), Color(0xFF092E21)],
      ),
    ),
    // 11: Dark - 鎏金岁月
    MixinTheme.buildTheme(
      brightness: Brightness.dark,
      primaryColor: Colors.amber[300],
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3E2723), Color(0xFF000000)],
      ),
    ),
    // 12: Dark - 熔岩之心 (新增)
    MixinTheme.buildTheme(
      brightness: Brightness.dark,
      primaryColor: Colors.redAccent[100],
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF641E16), Color(0xFF1B0000)],
      ),
    ),
    // 13: Dark - 深海 (新增)
    MixinTheme.buildTheme(
      brightness: Brightness.dark,
      primaryColor: Colors.cyan,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF003942), Color(0xFF011A20)],
      ),
    ),
    // 14: Dark - 可可大地 (新增)
    MixinTheme.buildTheme(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF8D6E63),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2E1E1A), Color(0xFF1A0A06)],
      ),
    ),

    // 15: Dark - 紫晶星云 (新增)
    MixinTheme.buildTheme(
      brightness: Brightness.dark,
      primaryColor: Colors.purpleAccent[100],
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2C0747), Color(0xFF0F0219)],
      ),
    ),
    // 16: Dark - 矩阵代码 (新增)
    MixinTheme.buildTheme(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF69F0AE),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF01180A), Color(0xFF000000)],
      ),
    ),

    // 17: Dark - 落日晚霞 (新增)
    MixinTheme.buildTheme(
      brightness: Brightness.dark,
      primaryColor: Colors.orange[300],
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2C1D38), Color(0xFF532432)],
      ),
    ),

    // 18: Dark - 凛冬冰川 (新增)
    MixinTheme.buildTheme(
      brightness: Brightness.dark,
      primaryColor: Colors.blue,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF14293D), Color(0xFF030D1A)],
      ),
    ),

    // 19: Dark - 水墨石墨 (新增)
    MixinTheme.buildTheme(
      brightness: Brightness.dark,
      primaryColor: Color(0xFF2B2B2B),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF333333), Color(0xFF555555)],
      ),
    ),
  ];

  /// 根据 index 获取 ThemeData
  static ThemeData getTheme({int? index}) {
    if (index == null || index < 0 || index >= _themeList.length) {
      return _themeList[0]; // 越界或为空时返回默认主题
    }
    return _themeList[index];
  }
}

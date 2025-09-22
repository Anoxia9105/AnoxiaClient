
import 'package:flutter/material.dart';
import 'package:notepadclient/core/utils/SPUtil.dart';
import 'package:notepadclient/shared/theme/AppTheme.dart';

/// 设置控制器
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  15:08
class SettingsController extends ChangeNotifier {
  ThemeData _theme = AppTheme.getTheme();

  int themeIndex=0;
  get theme => _theme;
  /// 设置主题
  ///
  /// 作者: anoxia
  ///
  /// 日期: 2025/9/16 15:37
  ///
  /// 参数:
  /// - [index]： 主题索引
  void setThemeMode(int index) {
    _theme = AppTheme.getTheme(index: index);
    SPUtil.instance.set<int>("theme", index);
    themeIndex=index;
    notifyListeners();
  }

  /// 启动获取设置参数
  ///
  /// 作者: anoxia
  ///
  /// 日期: 2025/9/16 15:37
  Future<void> loadSettings() async {
   int? index= SPUtil.instance.get<int>("theme",defValue: 0);
   themeIndex=index ?? 0;
   _theme = AppTheme.getTheme(index: index);
  }
}

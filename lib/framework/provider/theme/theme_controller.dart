import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../common/utils/SPUtil.dart';
import '../../theme/AppTheme.dart';

part 'theme_controller.g.dart';

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
  final index = ref.watch(themeIndexProvider);
  ThemeData baseTheme = AppTheme.getTheme(index: index);
  return baseTheme.copyWith(
    textTheme: baseTheme.textTheme.apply(fontFamily: 'HarmonyOS'),
    primaryTextTheme: baseTheme.primaryTextTheme.apply(fontFamily: 'HarmonyOS'),
  );
}

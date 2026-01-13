import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../common/utils/SPUtil.dart';
import '../../theme/AppTheme.dart';
import 'font_controller.dart';

part 'theme_controller.g.dart';

@Riverpod(keepAlive: true)
class ThemeIndex extends _$ThemeIndex {
  @override
  int build() {
    final themeIndex = SPUtil.instance.get<int>("theme_index", defValue: 0);
    return themeIndex!;
  }

  void setTheme(int index) {
    state = index;
    SPUtil.instance.set<int>("theme_index", index);
  }
}

@riverpod
ThemeData appTheme(Ref ref) {
  final index = ref.watch(themeIndexProvider);
  final fontFamily = ref.watch(fontControllerProvider);
  ThemeData baseTheme=AppTheme.getTheme(index: index);
  return baseTheme.copyWith(
    textTheme: baseTheme.textTheme.apply(fontFamily: fontFamily),
    primaryTextTheme: baseTheme.primaryTextTheme.apply(fontFamily: fontFamily),
  );
}

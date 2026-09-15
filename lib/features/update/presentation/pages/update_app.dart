import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anoxia/framework/domain/app_update_info.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'update_page.dart';

/// 独立「更新窗口」应用壳
///
/// 后台开启强制更新后，main.dart 会用 `runApp` 把整个界面替换成更新页。
/// 这条路径上既没有 `App()`（也就没有用户主题），也没有 GoRouter，
/// 直接挂 [UpdatePage] 会导致：
/// - 界面回落到 Material 默认蓝紫主题，与用户所选强调色/亮暗模式不一致；
/// - 更新页里任何 GoRouter 扩展调用直接抛 "No GoRouter found in context"。
///
/// 这里通过局部 [Theme] 同步用户主题。外层公共应用壳已经提供 MaterialApp，
/// 不再嵌套第二个 Navigator，避免返回栈、焦点与弹窗宿主产生歧义。
class UpdateApp extends ConsumerWidget {
  /// 更新信息
  final AppUpdateInfo updateInfo;

  const UpdateApp({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);

    return Theme(
      data: theme,
      child: UpdatePage(updateInfo: updateInfo, standalone: true),
    );
  }
}

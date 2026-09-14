import 'package:easy_localization/easy_localization.dart';
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
/// 这里补一层 MaterialApp：
/// - 主题取自 [appThemeProvider]，与用户在设置里选择的强调色/亮暗模式完全同步；
/// - 不引入 GoRouter，保证更新页在无路由环境下可用。
class UpdateApp extends ConsumerWidget {
  /// 更新信息
  final AppUpdateInfo updateInfo;

  const UpdateApp({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);

    return MaterialApp(
      title: 'Anoxia',
      theme: theme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // 与主应用一致：无障碍大字号下钳制缩放，避免小窗口布局溢出
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: child ?? const SizedBox.shrink(),
      ),
      home: UpdatePage(updateInfo: updateInfo, standalone: true),
    );
  }
}

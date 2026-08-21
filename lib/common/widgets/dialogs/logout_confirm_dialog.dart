import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';

/// 展示统一的退出登录二次确认弹窗
///
/// 返回 [true] 表示用户确认退出，调用方负责执行登出逻辑。
Future<bool> showLogoutConfirmDialog(BuildContext context) {
  return showEscClosableDialog<bool>(
    context: context,
    builder: (_) => const LogoutConfirmDialog(),
  ).then((result) => result ?? false);
}

/// 退出登录确认弹窗
///
/// 移动端抽屉与桌面端侧边栏共用，风格统一：
/// 顶部圆形警示图标 + 居中标题与文案 + 底部取消/退出按钮。
class LogoutConfirmDialog extends StatelessWidget {
  const LogoutConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SizedBox.square(
            dimension: 18,
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedLogout01,
              size: 14,
              color: colorScheme.onErrorContainer,
            ),
          ),
        ),
      ),
      title: Text(
        'logout'.tr(),
        textAlign: TextAlign.center,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Text(
        'logout_confirm_hint'.tr(),
        textAlign: TextAlign.center,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.outline,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Text('cancel'.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'logout'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

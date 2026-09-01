import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 展示统一的危险操作二次确认弹窗（删除会话 / 退出群聊 / 解散群聊）
///
/// 样式与退出登录弹窗（[logout_confirm_dialog.dart]）保持一致：
/// 顶部圆形警示图标 + 居中标题与文案 + 底部取消/确认按钮。
///
/// 返回 [true] 表示用户确认操作，调用方负责执行具体逻辑。
Future<bool> showDangerConfirmDialog(
  BuildContext context, {
  required List<List<dynamic>> icon,
  required String title,
  required String content,
  required String confirmLabel,
}) {
  return showEscClosableDialog<bool>(
    context: context,
    builder: (_) => DangerConfirmDialog(
      icon: icon,
      title: title,
      content: content,
      confirmLabel: confirmLabel,
    ),
  ).then((result) => result ?? false);
}

/// 危险操作确认弹窗
class DangerConfirmDialog extends StatelessWidget {
  const DangerConfirmDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.content,
    required this.confirmLabel,
  });

  /// 顶部圆形图标（HugeIcon）
  final List<List<dynamic>> icon;

  /// 弹窗标题
  final String title;

  /// 弹窗说明文案
  final String content;

  /// 确认按钮文案（如「删除会话」「退出群聊」）
  final String confirmLabel;

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
              icon: icon,
              size: 14,
              color: colorScheme.onErrorContainer,
            ),
          ),
        ),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Text(
        content,
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
              borderRadius: BorderRadius.circular(RadiusToken.lg),
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
              borderRadius: BorderRadius.circular(RadiusToken.lg),
            ),
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

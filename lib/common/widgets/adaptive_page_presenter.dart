// 自适应页面展示工具。
//
// 在移动端使用全屏路由，在桌面端使用尺寸受限的模态对话框，
// 实现跨平台统一的页面展示体验。
//
// 桌面弹窗统一式样约定：
// - 标题栏为「左侧返回按钮 + 左对齐标题」（弹窗内 AppBar 强制 centerTitle:false）
// - 支持 ESC 键关闭（Flutter 默认 ESC 关闭依赖 barrierDismissible，
//   本工具保持点击遮罩不关闭，同时显式接管 ESC）
import 'package:anoxia/common/utils/device_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Uses a page route on mobile and a size-constrained modal on desktop.
Future<T?> presentAdaptivePage<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final useDialog =
      DeviceUtil.isRealDesktop() ||
      (DeviceUtil.isWeb && DeviceUtil.isDesktop(context));

  if (!useDialog) {
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute<T>(builder: builder));
  }

  final screenSize = MediaQuery.sizeOf(context);
  final dialogWidth = (screenSize.width - 48).clamp(320.0, 760.0).toDouble();
  final dialogHeight = (screenSize.height - 48).clamp(320.0, 760.0).toDouble();

  // 减少动效时弹窗零时长即时呈现，否则走默认 150ms 淡入+缩放
  final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  if (reduce) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(
        context,
      ).modalBarrierDismissLabel,
      pageBuilder: (dialogContext, _, _) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: _EscClosable(
            onEscape: () => Navigator.of(dialogContext).pop(),
            // 统一弹窗标题栏式样：AppBar 标题左对齐，与自动返回按钮组成
            // 「返回按钮 + 标题」的桌面弹窗标准头部。
            child: Theme(
              data: Theme.of(dialogContext).copyWith(
                appBarTheme: Theme.of(dialogContext).appBarTheme.copyWith(
                      centerTitle: false,
                    ),
              ),
              child: Builder(builder: builder),
            ),
          ),
        ),
      ),
      transitionDuration: Duration.zero,
    );
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: _EscClosable(
          onEscape: () => Navigator.of(dialogContext).pop(),
          // 统一弹窗标题栏式样：AppBar 标题左对齐，与自动返回按钮组成
          // 「返回按钮 + 标题」的桌面弹窗标准头部。
          child: Theme(
            data: Theme.of(dialogContext).copyWith(
              appBarTheme: Theme.of(dialogContext).appBarTheme.copyWith(
                    centerTitle: false,
                  ),
            ),
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  );
}

/// 判断当前页面是否以桌面模态对话框形式展示（配合 [presentAdaptivePage] 使用）。
///
/// 桌面端详情页以对话框展示，移动端为普通路由。操作完成后需关闭对话框时，
/// 用此帮助方法区分：返回 true 表示应 `Navigator.pop`，false 表示普通页面无需操作。
bool isAdaptiveDialog(BuildContext context) =>
    ModalRoute.of(context) is PopupRoute;

/// 与 [presentAdaptivePage] 同款式样的对话框弹出助手。
///
/// 适用于不走整页 Scaffold 的表单/选择类 [Dialog]：
/// 仅注入统一的 ESC 关闭能力（ESC = pop），不改样式。
Future<T?> showEscClosableDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = false,
  Color? barrierColor,
}) {
  // 减少动效时零时长即时呈现，否则走 showDialog 默认过渡
  final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  if (reduce) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: MaterialLocalizations.of(
        context,
      ).modalBarrierDismissLabel,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, _, _) => _EscClosable(
        onEscape: () => Navigator.of(dialogContext).pop(),
        child: builder(dialogContext),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    builder: (dialogContext) => _EscClosable(
      onEscape: () => Navigator.of(dialogContext).pop(),
      child: builder(dialogContext),
    ),
  );
}

/// ESC 关闭包装：按下 ESC 时回调 [onEscape]。
///
/// Flutter 内置的 ESC 关闭（DismissIntent）只在 barrierDismissible=true
/// 时生效；这里显式接管，保证「点击遮罩不关闭」的同时 ESC 可用。
/// 内部 Focus 自动持有焦点，使快捷键在弹窗内任何位置（含空白处）生效；
/// 焦点进入输入框后按键事件仍会沿焦点链冒泡到本节点，ESC 同样可关闭。
class _EscClosable extends StatelessWidget {
  final VoidCallback onEscape;
  final Widget child;

  const _EscClosable({required this.onEscape, required this.child});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): onEscape,
      },
      child: Focus(
        autofocus: true,
        canRequestFocus: true,
        skipTraversal: true,
        child: child,
      ),
    );
  }
}

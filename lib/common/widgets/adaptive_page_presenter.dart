// 自适应页面展示工具。
//
// 在移动端使用全屏路由，在桌面端使用尺寸受限的模态对话框，
// 实现跨平台统一的页面展示体验。
import 'package:anoxia/common/utils/device_util.dart';
import 'package:flutter/material.dart';

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

  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: builder(dialogContext),
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

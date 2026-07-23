import 'package:anoxia/common/utils/DeviceUtil.dart';
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

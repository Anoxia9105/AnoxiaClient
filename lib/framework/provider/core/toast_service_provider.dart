import 'package:anoxia/common/widgets/toast.dart' show Toast;
import 'package:anoxia/framework/core/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:anoxia/framework/core/toast_service.dart' show ToastType;

/// 默认 Toast 服务实现
///
/// 该实现包装 [Toast] 类，提供与 [ToastService] 接口兼容的实现。
/// 由 Riverpod 注入，供数据层（Provider）使用，避免直接依赖 UI 代码。
class DefaultToastService implements ToastService {
  @override
  void showNotificationNow(
    String message, {
    Color? color,
    String? typeMessage,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Toast.showNotificationNow(
      message,
      color: color,
      typeMessage: typeMessage,
      type: type,
      duration: duration,
    );
  }

  @override
  void showToast(
    String message, {
    ToastType type = ToastType.info,
    Alignment align = Alignment.bottomCenter,
    Duration duration = const Duration(seconds: 3),
  }) {
    Toast.showToast(message, type: type, align: align, duration: duration);
  }

  @override
  Function showWidgetOffset({
    required Offset target,
    dynamic preferDirection,
    required Widget child,
    VoidCallback? onClose,
  }) {
    return Toast.showWidgetOffset(
      target: target,
      direction: preferDirection,
      child: child,
      onClose: onClose,
    );
  }
}

/// Toast 服务 Provider
///
/// 提供 [ToastService] 接口的实现。数据层（Provider）通过此 Provider
/// 获取 Toast 服务实例，避免直接依赖 [Toast] 类。
final toastServiceProvider = Provider<ToastService>((ref) {
  return DefaultToastService();
});

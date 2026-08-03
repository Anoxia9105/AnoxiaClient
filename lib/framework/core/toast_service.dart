import 'package:flutter/material.dart';

/// Toast 类型枚举
///
/// 用于指定 Toast 的样式主题
enum ToastType { warning, error, success, info }

/// Toast 服务抽象接口
///
/// 该接口定义了数据层（Provider）与 UI 层（Toast）之间的解耦契约。
/// 数据层不应直接依赖 UI 组件，只能通过该接口与 Toast 服务交互。
/// 具体实现由 UI 层提供，并通过 Riverpod 注入。
abstract class ToastService {
  /// 显示字符串内容的通知框（立即显示）
  void showNotificationNow(
    String message, {
    Color? color,
    String? typeMessage,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  });

  /// 显示文本提示框
  void showToast(
    String message, {
    ToastType type = ToastType.info,
    Alignment align = Alignment.bottomCenter,
    Duration duration = const Duration(seconds: 3),
  });

  /// 显示自定义 Widget（关联 coordinates）
  Function showWidgetOffset({
    required Offset target,
    dynamic preferDirection,
    required Widget child,
    VoidCallback? onClose,
  });
}

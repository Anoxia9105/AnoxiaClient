import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

import '../../framework/core/toast_service.dart';

export '../../framework/core/toast_service.dart' show ToastType;

/// 全局 SnackBar 工具。
///
/// 类名为兼容现有调用保留；所有文本通知均通过 [ScaffoldMessenger] 显示，
/// BotToast 仅继续承载依附式菜单等非通知浮层。
class Toast {
  static const _defaultDuration = Duration(seconds: 3);
  static const _mobileMargin = EdgeInsets.fromLTRB(16, 0, 16, 16);
  static const _desktopWidth = 400.0;

  /// 每个应用/独立窗口的 MaterialApp 都应注册此 key。
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// 显示字符串内容的通知框（立即显示）。
  static VoidCallback showNotificationNow(
    String message, {
    Color? color,
    VoidCallback? onTap,
    Alignment? alignment,
    String? typeMessage,
    ToastType type = ToastType.info,
    Duration duration = _defaultDuration,
  }) {
    return _showSnackBar(
      message,
      type: type,
      duration: duration,
      backgroundColor: color,
      onTap: onTap,
    );
  }

  /// 显示纯文字 SnackBar。
  static void showToast(
    String message, {
    ToastType type = ToastType.info,
    Alignment align = Alignment.bottomCenter,
    Duration duration = _defaultDuration,
    bool singleton = false,
  }) {
    _showSnackBar(message, type: type, duration: duration);
  }

  /// 显示纯文字 SnackBar。
  static void showToastTheme(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Alignment align = Alignment.bottomCenter,
    Duration duration = const Duration(seconds: 6),
    bool singleton = false,
  }) {
    _showSnackBar(message, type: type, duration: duration);
  }

  /// 显示自定义 Widget（关联 context）。
  static Function showWidget(
    BuildContext context, {
    required Widget child,
    PreferDirection direction = PreferDirection.topLeft,
    VoidCallback? onClose,
  }) {
    return BotToast.showAttachedWidget(
      targetContext: context,
      preferDirection: direction,
      attachedBuilder: (_) => child,
      onClose: onClose,
    );
  }

  /// 显示自定义 Widget（关联 coordinates）。
  static Function showWidgetOffset({
    required Offset target,
    PreferDirection direction = PreferDirection.topLeft,
    required Widget child,
    VoidCallback? onClose,
  }) {
    return BotToast.showAttachedWidget(
      target: target,
      preferDirection: direction,
      attachedBuilder: (_) => FocusScope(canRequestFocus: false, child: child),
      onClose: onClose,
    );
  }

  static VoidCallback _showSnackBar(
    String message, {
    required ToastType type,
    required Duration duration,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    final messenger = messengerKey.currentState;
    final context = messengerKey.currentContext;
    if (messenger == null || context == null) return () {};

    final isDesktopWidth = MediaQuery.sizeOf(context).width >= 600;
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ),
        backgroundColor: backgroundColor ?? _colorFor(type),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        width: isDesktopWidth ? _desktopWidth : null,
        margin: isDesktopWidth ? null : _mobileMargin,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 6,
      ),
    );
    return controller.close;
  }

  static Color _colorFor(ToastType type) {
    return switch (type) {
      ToastType.success => const Color(0xFF2E7D32),
      ToastType.error => const Color(0xFFB3261E),
      ToastType.warning => const Color(0xFF8A5A00),
      ToastType.info => const Color(0xFF455A64),
    };
  }
}

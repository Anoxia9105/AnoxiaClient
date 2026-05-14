import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Toast 类型枚举
///
/// 用于指定 Toast 的样式主题
enum ToastType { warning, error, success, info }

/// Toast 工具类
///
/// 封装 BotToast 插件，提供统一的提示框功能。
/// 支持多种显示形式：自定义内容、字符串提示、Widget 等。
class Toast {
  static const _defaultDuration = Duration(seconds: 3);
  static const _defaultMargin = EdgeInsets.all(15);
  static const _defaultIconSize = 13.0;
  static const _defaultRadius = 9.0;

  /// Windows 桌面端禁用毛玻璃效果，避免兼容性问题
  static bool get _enableBlurEffect {
    if (kIsWeb) return true;
    return defaultTargetPlatform != TargetPlatform.windows;
  }

  /// 显示自定义内容的通知框
  static Function showNotification({
    Color color = Colors.blueGrey,
    VoidCallback? onTap,
    Alignment? alignment,
    Duration? duration,
    EdgeInsets? margin,
    Widget Function(void Function())? title,
    Widget Function(void Function())? subtitle,
    Widget Function(void Function())? leading,
    Widget Function(void Function())? trailing,
  }) {
    return BotToast.showNotification(
      onTap: onTap,
      align: alignment,
      duration: duration ?? _defaultDuration,
      margin: margin ?? _defaultMargin,
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      backgroundColor: color,
    );
  }

  /// 显示字符串内容的通知框（立即显示）
  static Function showNotificationNow(
    String message, {
    Color? color,
    VoidCallback? onTap,
    Alignment? alignment,
    String? typeMessage,
    ToastType type = ToastType.info,
    Duration duration = _defaultDuration,
  }) {
    const white = Colors.white;
    final config = _toastConfig(type);
    final resolvedColor = color ?? config.color;

    return BotToast.showNotification(
      onTap: onTap,
      align: alignment,
      duration: duration,
      margin: _defaultMargin,
      title: (_) => Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
      leading: (_) => config.icon,
      trailing: (_) =>
          Text(typeMessage ?? '', style: const TextStyle(color: white)),
      backgroundColor: resolvedColor,
    );
  }

  /// 显示文本提示框
  static void showToast(
    String message, {
    ToastType type = ToastType.info,
    Alignment align = Alignment.bottomCenter,
    Duration duration = const Duration(seconds: 3),
  }) {
    final config = _toastConfig(type);
    _buildToast(message, config.color, config.icon, align, duration);
  }

  /// 显示主题色的提示框
  static void showToastTheme(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Alignment align = Alignment.bottomCenter,
    Duration duration = const Duration(seconds: 6),
  }) {
    final config = _toastConfig(
      type,
      defaultColor: Theme.of(context).primaryColor,
    );
    _buildToast(message, config.color, config.icon, align, duration);
  }

  /// 显示自定义 Widget（关联 context）
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

  /// 显示自定义 Widget（关联坐标）
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

  /// 构建 Toast 视图
  static void _buildToast(
    String message,
    Color color,
    Icon icon,
    Alignment align,
    Duration duration,
  ) {
    BotToast.showCustomText(
      align: align,
      duration: duration,
      toastBuilder: (_) {
        final toastBody = Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(_defaultRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: .18),
              width: 0.8,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.12),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon.icon,
                  color: Colors.white,
                  size: _defaultIconSize,
                ),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    height: 1.28,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );

        return SafeArea(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_defaultRadius),
            child: _enableBlurEffect
                ? BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: toastBody,
                  )
                : toastBody,
          ),
        );
      },
    );
  }

  /// 获取 Toast 配置
  static _ToastConfig _toastConfig(ToastType type, {Color? defaultColor}) {
    switch (type) {
      case ToastType.warning:
        return _ToastConfig(
          defaultColor ?? const Color.fromRGBO(230, 162, 60, 1),
          const Icon(
            Icons.warning_amber,
            color: Colors.white,
            size: _defaultIconSize,
          ),
        );
      case ToastType.error:
        return _ToastConfig(
          defaultColor ?? const Color.fromRGBO(245, 108, 108, 1),
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: _defaultIconSize,
          ),
        );
      case ToastType.success:
        return _ToastConfig(
          defaultColor ?? const Color.fromRGBO(103, 194, 58, 1),
          const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: _defaultIconSize,
          ),
        );
      case ToastType.info:
        return _ToastConfig(
          defaultColor ?? const Color.fromRGBO(144, 147, 153, 1),
          const Icon(
            Icons.info_outline,
            color: Colors.white,
            size: _defaultIconSize,
          ),
        );
    }
  }
}

/// Toast 配置内部类
class _ToastConfig {
  final Color color;
  final Icon icon;

  _ToastConfig(this.color, this.icon);
}

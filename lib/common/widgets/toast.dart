import 'dart:ui';
import 'package:hugeicons/hugeicons.dart';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../framework/core/toast_service.dart';

export '../../framework/core/toast_service.dart' show ToastType;

/// Toast 工具类
///
/// 封装 BotToast 插件，提供统一的提示框功能。
/// 支持多种显示形式：自定义内容、字符串提示、Widget 等。
class Toast {
  static const _defaultDuration = Duration(seconds: 3);
  static const _defaultMargin = EdgeInsets.all(15);
  static const _defaultIconSize = 15.0;
  static const _defaultRadius = 14.0;

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

    try {
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
    } catch (e) {
      debugPrint('BotToast is not ready: $e');
      return () {};
    }
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

  /// 显示自定义 Widget（关联 coordinates）
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
    Widget icon,
    Alignment align,
    Duration duration,
  ) {
    final surfaceColor = Color.lerp(color, Colors.black, 0.16) ?? color;

    BotToast.showCustomText(
      align: align,
      duration: duration,
      animationDuration: const Duration(milliseconds: 1),
      animationReverseDuration: const Duration(milliseconds: 1),
      toastBuilder: (_) {
        final toastBody = Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, surfaceColor],
            ),
            borderRadius: BorderRadius.circular(_defaultRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: .16),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .30),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: .16),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .20),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .26),
                    width: 1,
                  ),
                ),
                child: icon,
              ),
              const SizedBox(width: 11),
              Flexible(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Colors.white,
                    height: 1.35,
                    letterSpacing: 0.1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );

        final body = SafeArea(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_defaultRadius),
            child: _enableBlurEffect
                ? BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: toastBody,
                  )
                : toastBody,
          ),
        );

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, (1 - value) * 12),
              child: Transform.scale(
                scale: 0.96 + 0.04 * value,
                alignment: Alignment.center,
                child: Opacity(opacity: value, child: child),
              ),
            );
          },
          child: body,
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
          const HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            color: Colors.white,
            size: _defaultIconSize,
          ),
        );
      case ToastType.error:
        return _ToastConfig(
          defaultColor ?? const Color.fromRGBO(245, 108, 108, 1),
          const HugeIcon(
            icon: HugeIcons.strokeRoundedAlertCircle,
            color: Colors.white,
            size: _defaultIconSize,
          ),
        );
      case ToastType.success:
        return _ToastConfig(
          defaultColor ?? const Color.fromRGBO(103, 194, 58, 1),
          const HugeIcon(
            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
            color: Colors.white,
            size: _defaultIconSize,
          ),
        );
      case ToastType.info:
        return _ToastConfig(
          defaultColor ?? const Color.fromRGBO(144, 147, 153, 1),
          const HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
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
  final Widget icon;

  _ToastConfig(this.color, this.icon);
}

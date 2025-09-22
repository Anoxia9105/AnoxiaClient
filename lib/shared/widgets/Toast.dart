import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

class Toast{


  ///通知框
  ///自定义内容
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
      duration: duration ?? const Duration(seconds: 3),
      margin: margin ?? const EdgeInsets.all(15),
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: title,
      backgroundColor: color,
    );
  }

  ///显示通知框
  ///字符串消息
  static Function showNotificationNow(
      String message, {
        Color color = Colors.black54,
        VoidCallback? onTap,
        Alignment? alignment,
        String? typeMessage,
      }) {
    Color white = Colors.white;
    return BotToast.showNotification(
      onTap: onTap,
      align: alignment,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(15),
      title: (v) => Text(message, style: TextStyle(color: white, fontSize: 16)),
      leading: (v) => Icon(Icons.info_outline, color: white),
      trailing: (v) => Text(typeMessage ?? '', style: TextStyle(color: white)),
      backgroundColor: color,
    );
  }

  ///提示框 支持类型
  static void showToast(
      String message, {
        ToastType? type,
        Alignment align = Alignment.bottomCenter,
      }) {
    // BotToast.showText(text: message,contentColor: const Color.fromRGBO(103, 194, 58, 1));
    Icon icon;
    Color color;
    switch (type) {
      case ToastType.warning:
        color = const Color.fromRGBO(230, 162, 60, 1);
        icon = const Icon(Icons.warning_amber, color: Colors.white, size: 15);
        break;
      case ToastType.error:
        color = const Color.fromRGBO(245, 108, 108, 1);
        icon = const Icon(Icons.error_outline, color: Colors.white, size: 15);
        break;
      case ToastType.success:
        color = const Color.fromRGBO(103, 194, 58, 1);
        icon = const Icon(
          Icons.check_circle_outline,
          color: Colors.white,
          size: 15,
        );
        break;
      default:
        color = const Color.fromRGBO(144, 147, 153, 1);
        icon = const Icon(Icons.info_outline, color: Colors.white, size: 15);
        break;
    }

    BotToast.showCustomText(
      align: align,
      duration: Duration(seconds: 6),
      toastBuilder: (void Function() cancelFunc) {
        return Container(
          padding: const EdgeInsets.only(
            left: 14,
            right: 14,
            top: 5,
            bottom: 7,
          ),
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 3, right: 3),
                child: icon,
              ),
              Text(
                message,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  ///根据主题色提示框
  static void showToastTheme(
      BuildContext context,
      String message, {
        ToastType? type,
        Alignment align = Alignment.bottomCenter,
      }) {
    // BotToast.showText(text: message,contentColor: const Color.fromRGBO(103, 194, 58, 1));
    Icon icon;
    Color color = Theme.of(context).primaryColor;
    switch (type) {
      case ToastType.warning:
        icon = const Icon(Icons.warning_amber, color: Colors.white, size: 15);
        break;
      case ToastType.error:
        icon = const Icon(Icons.error_outline, color: Colors.white, size: 15);
        break;
      case ToastType.success:
        icon = const Icon(
          Icons.check_circle_outline,
          color: Colors.white,
          size: 15,
        );
        break;
      default:
        icon = const Icon(Icons.info_outline, color: Colors.white, size: 15);
        break;
    }

    BotToast.showCustomText(
      align: align,
      toastBuilder: (void Function() cancelFunc) {
        return Container(
          padding: const EdgeInsets.only(
            left: 14,
            right: 14,
            top: 5,
            bottom: 7,
          ),
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 3, right: 3),
                child: icon,
              ),
              Text(
                message,
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  ///根据context显示Widget
  ///一般使用Build组件定位
  static Function showWidget(
      BuildContext context, {
        required Widget child,
        PreferDirection direction = PreferDirection.topLeft,
        VoidCallback? onClose,
      }) {
    return BotToast.showAttachedWidget(
      targetContext: context,
      preferDirection: direction,
      attachedBuilder: (void Function() cancelFunc) {
        return child;
      },
      onClose: onClose,
    );
  }

  ///根据Offset显示Widget
  static Function showWidgetOffset({
    required Offset target,
    PreferDirection direction = PreferDirection.topLeft,
    required Widget child,
    VoidCallback? onClose,
  }) {
    return BotToast.showAttachedWidget(
      target: target,
      preferDirection: direction,
      attachedBuilder: (void Function() cancelFunc) {
        return FocusScope(canRequestFocus: false, child: child);
      },
      onClose: onClose,
    );
  }
}

enum ToastType { warning, error, success, info }
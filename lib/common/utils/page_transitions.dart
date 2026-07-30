import 'package:flutter/material.dart';

/// 页面切换动画类型
enum PageTransitionType {
  fade,
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  slideFromTop,
  scale,
  rotate,
}

/// 页面切换动画工具
///
/// 提供多种页面切换动画效果，支持自定义时长和缓动曲线。
class PageTransitions {
  /// 创建带动画的路由
  ///
  /// [page] 目标页面组件
  /// [type] 动画类型，默认为淡入淡出
  /// [duration] 动画时长，默认为 300 毫秒
  /// [curve] 缓动曲线，默认为 Curves.easeInOut
  static Route createRoute(
      Widget page, {
        PageTransitionType type = PageTransitionType.fade,
        Duration duration = const Duration(milliseconds: 300),
        Curve curve = Curves.easeInOut,
      }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        switch (type) {
          case PageTransitionType.fade:
            return FadeTransition(
              opacity: curvedAnimation,
              child: child,
            );

          case PageTransitionType.slideFromRight:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );

          case PageTransitionType.slideFromLeft:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );

          case PageTransitionType.slideFromBottom:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );

          case PageTransitionType.slideFromTop:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );

          case PageTransitionType.scale:
            return ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
              child: child,
            );

          case PageTransitionType.rotate:
            return RotationTransition(
              turns: Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
              child: child,
            );
        }
      },
    );
  }
}

import 'package:flutter/material.dart';

enum PageTransitionType {
  fade,
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  slideFromTop,
  scale,
  rotate,
}

class PageTransitions {
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

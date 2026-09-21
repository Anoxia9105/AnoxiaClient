import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 减少动效统一门控。
///
/// [app.dart] 已把 `reduceMotionProvider` 写入全局
/// `MediaQuery.disableAnimations`，所以这里只读 MediaQuery，
/// 各调用方无需再 watch provider。
bool isReduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// 正常时长 vs 减少动效时直接零时长。
Duration motionDuration(BuildContext context, Duration normal) =>
    isReduceMotion(context) ? Duration.zero : normal;

/// 路由转场 Builder：减少动效时直接返回子节点（无滑动/淡入），
/// 否则委托给 iOS 风格的 [CupertinoPageTransitionsBuilder]。
class ReduceMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const ReduceMotionPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return child;
    }
    return const CupertinoPageTransitionsBuilder().buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

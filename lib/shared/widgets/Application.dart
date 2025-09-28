import 'package:flutter/material.dart';

/// 程序相关操作
///
/// 作者: anoxia
///
/// 版本: 2.0.0
///
/// 创建时间: 2025-09-16  18:05
class Application {
  //获取APP logo
  static Widget getAppLogo({
    double width = 48,
    double height = 48,
    Widget? child,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            "assets/images/app_icon.png",
            width: width,
            height: height,
          ),
          // ,
          if (child != null) ...[SizedBox(height: 10), child],
        ],
      ),
    );
  }

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

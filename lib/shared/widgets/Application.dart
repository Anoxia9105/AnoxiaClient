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
  static Widget getAppLogo({double width=48,double height=48,Widget? child}){
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset("assets/images/app_icon.png",width: width,height: height),
          SizedBox(height: 10),
          if(child!=null)child
        ],
      ),
    );
  }

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static GlobalKey<NavigatorState> pageNavigatorKey = GlobalKey<NavigatorState>();

}
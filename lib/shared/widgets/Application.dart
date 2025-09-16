import 'package:flutter/material.dart';

/// TODO 描述
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  18:05
class Application {
  //获取APP logo
  static Widget getAppLogo({double width=48,double height=48}){
    return Image.asset("assets/images/app_icon.png",width: width,height: height);
  }
}
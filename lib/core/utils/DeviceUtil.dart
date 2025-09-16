import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 设备类型工具类
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  16:22
class DeviceUtil {
  /// 是否是桌面端
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  /// 是否是移动端
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  //是否是web
  static bool get isWeb{
    if (kIsWeb) return true;
    return false;
  }

  /// 是否是平板（通过屏幕宽度判断）
  /// [tabletMinWidth] 默认 600，可根据需求调整
  static bool isTablet(BuildContext context, {double tabletMinWidth = 600}) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= tabletMinWidth;
  }

  /// 获取设备类型
  static DeviceType getDeviceType(BuildContext context) {
    if (isDesktop) return DeviceType.desktop;
    if (isTablet(context)) return DeviceType.tablet;
    return DeviceType.mobile;
  }
}

enum DeviceType{
  //桌面
  desktop,
  //平板
  tablet,
  //手机
  mobile,
}
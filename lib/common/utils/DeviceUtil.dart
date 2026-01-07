import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 设备类型工具类
///
/// 作者: anoxia
///
/// 版本: 2.0.0
///
/// 创建时间: 2025-09-26
class DeviceUtil {
  /// 断点定义，可以按需调整
  static const double mobileMaxWidth = 600;   // 手机最大宽度
  static const double tabletMaxWidth = 1024;  // 平板最大宽度

  /// 是否是 Web
  static bool get isWeb => kIsWeb;

  /// 根据屏幕宽度判断设备类型
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width <= mobileMaxWidth) {
      return DeviceType.mobile;
    } else if (width <= tabletMaxWidth) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// 判断是否是手机
  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  /// 判断是否是平板
  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  /// 判断是否是桌面
  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;


  ///真实的桌面环境 不是web
  static bool isRealDesktop() =>!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  ///真实手机环境
  static bool isRealMobile() =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  ///真实web环境
  static bool isRealWeb() => kIsWeb;
}

enum DeviceType {
  desktop,
  tablet,
  mobile,
}

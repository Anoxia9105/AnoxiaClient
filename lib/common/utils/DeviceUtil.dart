import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 设备类型工具类
///
/// 根据屏幕宽度和运行平台判断当前设备类型，
/// 用于实现响应式布局和平台适配。
class DeviceUtil {
  /// 手机最大宽度阈值
  static const double mobileMaxWidth = 600;

  /// 平板最大宽度阈值
  static const double tabletMaxWidth = 1024;

  /// 是否为 Web 环境
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

  /// 判断是否为手机
  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  /// 判断是否为平板
  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  /// 判断是否为桌面端
  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  /// 判断是否为真实桌面环境（不包括 Web）
  static bool isRealDesktop() => !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// 判断是否为真实移动设备（不包括 Web）
  static bool isRealMobile() =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// 判断是否为真实 Web 环境
  static bool isRealWeb() => kIsWeb;
}

/// 设备类型枚举
enum DeviceType {
  desktop,
  tablet,
  mobile,
}

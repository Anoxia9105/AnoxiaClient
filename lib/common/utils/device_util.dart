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

  /// 主界面支持的最小屏幕宽度（逻辑像素）
  ///
  /// 低于该宽度时聊天/联系人等核心布局可能溢出或无法操作，
  /// 统一按此阈值拦截并展示「不支持过小设备」提示页。
  static const double minSupportedWidth = 320;

  /// 主界面支持的最小屏幕高度（逻辑像素）
  ///
  /// 只用于拦截被压得过扁的窗口（如 Web 端手动缩得很矮的浏览器窗口）。
  /// 阈值不能过高，否则会误伤横屏手机（如 iPhone SE 横屏高恰为 320）。
  static const double minSupportedHeight = 240;

  /// 判断屏幕尺寸是否过小、无法正常展示主界面
  static bool isScreenTooSmall(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width < minSupportedWidth || size.height < minSupportedHeight;
  }

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


  /// 判断是不是macOS
  static bool isMacOS() =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
  /// 判断是不是Windows
  static bool isWindows() =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  /// 判断是不是Linux
  static bool isLinux() =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
  /// 判断是不是Android
  static bool isAndroid() =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  /// 判断是不是iOS
  static bool isIOS() =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}

/// 设备类型枚举
enum DeviceType {
  desktop,
  tablet,
  mobile,
}

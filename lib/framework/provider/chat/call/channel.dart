import 'package:anoxia/platform/shims/desktop_multi_window_shim.dart';
import 'package:flutter/services.dart';

import '../../../../common/utils/device_util.dart';

/// 通话窗口通信通道
///
/// 提供跨平台的通话窗口通信能力，自动适配桌面端和移动端的不同实现：
/// - 桌面端：使用 WindowMethodChannel 实现多窗口通信
/// - 移动端：使用标准 MethodChannel 与原生通信
class Channel {
  /// 通话通道方法名：更新设置
  static const String callChannelMethod = 'updateSettings';
  static const String callWindowReadyMethod = 'on_call_window_ready';
  static const String callAcceptedMethod = 'on_call_accepted';

  /// 子窗口每次 HTTP 请求领取主窗口当前登录态，不依赖引擎各自的存储缓存。
  static const String callWindowAuthMethod = 'get_call_window_auth';

  /// 子窗口开始结束通话：主窗口应立即发送 CALL_END，但继续持有窗口状态。
  static const String callWindowEndingMethod = 'on_call_window_ending';

  /// 子窗口已完成媒体清理并即将销毁：主窗口清除窗口状态。
  static const String callWindowCloseMethod = 'on_call_window_close';

  /// 桌面端通话通道实例（懒加载）
  static WindowMethodChannel? _desktopCallChannel;

  /// 移动端通话通道实例
  static const MethodChannel _mobileCallChannel = MethodChannel(
    'call_windows_handler',
  );

  /// 获取当前平台的通话通道
  static dynamic get callChannel {
    if (DeviceUtil.isRealDesktop()) {
      _desktopCallChannel ??= const WindowMethodChannel('call_windows_handler');
      return _desktopCallChannel!;
    }
    return _mobileCallChannel;
  }
}

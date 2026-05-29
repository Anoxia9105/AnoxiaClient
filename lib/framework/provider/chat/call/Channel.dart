import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';

import '../../../../common/utils/DeviceUtil.dart';

/// 通话窗口通信通道
///
/// 提供跨平台的通话窗口通信能力，自动适配桌面端和移动端的不同实现：
/// - 桌面端：使用 WindowMethodChannel 实现多窗口通信
/// - 移动端：使用标准 MethodChannel 与原生通信
class Channel {
  /// 通话通道方法名：更新设置
  static const String callChannelMethod = 'updateSettings';

  /// 桌面端通话通道实例（懒加载）
  static WindowMethodChannel? _desktopCallChannel;

  /// 移动端通话通道实例
  static const MethodChannel _mobileCallChannel = MethodChannel(
    'call_windows_handler',
  );

  /// 获取当前平台的通话通道
  static dynamic get callChannel {
    if (DeviceUtil.isRealDesktop()) {
      _desktopCallChannel ??= WindowMethodChannel('call_windows_handler');
      return _desktopCallChannel!;
    }
    return _mobileCallChannel;
  }
}

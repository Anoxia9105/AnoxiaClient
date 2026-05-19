import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// 窗口控制器扩展
///
/// 为桌面多窗口功能提供便捷的窗口操作方法
extension WindowControllerExtension on WindowController {

  /// 自定义初始化窗口控制器
  ///
  /// 注册自定义的窗口方法处理器，支持窗口居中、关闭等操作
  Future<void> doCustomInitialize() async {
    return await setWindowMethodHandler((call) async {
      switch (call.method) {
        case 'window_center':
          return await windowManager.center();
        case 'window_close':
          return await windowManager.close();
        default:
          throw MissingPluginException(
            'Not implemented method: ${call.method}',
          );
      }
    });
  }

  /// 将窗口居中显示
  Future<void> center() {
    return invokeMethod('window_center');
  }

  /// 关闭当前窗口
  Future<void> close() {
    return invokeMethod('window_close');
  }
}

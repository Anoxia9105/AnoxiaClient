// Web 端 desktop_multi_window 空实现桩。
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class WindowConfiguration {
  final bool? hiddenAtLaunch;
  final dynamic arguments;
  final String? title;
  const WindowConfiguration({this.hiddenAtLaunch, this.arguments, this.title});
}

class WindowController {
  static Future<WindowController> fromCurrentEngine() async =>
      WindowController();

  static Future<WindowController> create(WindowConfiguration configuration) async =>
      WindowController();

  Future<void> setWindowMethodHandler(
    Future<dynamic> Function(MethodCall call)? handler,
  ) async {}

  Future<dynamic> invokeMethod(String method, [dynamic arguments]) async => null;

  Future<void> doCustomInitialize() async {}
  dynamic get arguments => null;
  Future<void> setTitle(String title) async {}
  Future<void> setFrame(dynamic frame) async {}
  Future<void> show() async {}
  Future<void> hide() async {}
}

/// 桌面端多窗口通信通道（Web 端无原生窗口概念，全部为 no-op）。
class WindowMethodChannel {
  final String name;
  const WindowMethodChannel(this.name);

  void setMethodCallHandler(
    Future<dynamic> Function(MethodCall call)? handler,
  ) {}

  Future<dynamic> invokeMethod(String method, [dynamic arguments]) async => null;
}

/// 桌面端拖拽移动窗口区域（Web 端退化为普通容器）。
class DragToMoveArea extends StatelessWidget {
  final Widget child;
  const DragToMoveArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

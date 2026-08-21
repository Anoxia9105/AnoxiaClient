// Web 端 window_manager 空实现桩。
// 仅在浏览器编译（dart.library.html）时被引用；所有方法均为 no-op，
// 因为 Web 没有原生窗口概念。类名/方法签名需与真实包保持一致以便调用点编译通过。
import 'package:flutter/widgets.dart';

enum TitleBarStyle { hidden, normal }

class WindowOptions {
  final Size? size;
  final Size? minimumSize;
  final Size? maximumSize;
  final bool? center;
  final Color? backgroundColor;
  final bool? skipTaskbar;
  final TitleBarStyle? titleBarStyle;
  final bool? alwaysOnTop;
  final String? title;
  final bool? fullScreen;
  final bool? focusOnShow;

  const WindowOptions({
    this.size,
    this.minimumSize,
    this.maximumSize,
    this.center,
    this.backgroundColor,
    this.skipTaskbar,
    this.titleBarStyle,
    this.alwaysOnTop,
    this.title,
    this.fullScreen,
    this.focusOnShow,
  });
}

/// 与真实包同名的监听器混入，供 `with WindowListener` 调用点使用。
mixin WindowListener {
  void onWindowCloseRequested() {}
  Future<void> onWindowClose() async {}
  void onWindowFocus() {}
  void onWindowBlur() {}
  void onWindowMaximize() {}
  void onWindowUnmaximize() {}
  void onWindowMinimize() {}
  void onWindowRestore() {}
  void onWindowResize(dynamic rect) {}
  void onWindowResized(dynamic rect) {}
  void onWindowMove(dynamic rect) {}
  void onWindowMoved(dynamic rect) {}
  void onWindowEnterFullScreen() {}
  void onWindowLeaveFullScreen() {}
  void onWindowShow() {}
  void onWindowHide() {}
}

class WindowManager {
  Future<void> ensureInitialized() async {}
  Future<void> setIcon(String path) async {}
  Future<void> waitUntilReadyToShow(
    WindowOptions options,
    Future<void> Function() callback,
  ) async {
    await callback();
  }

  Future<void> show() async {}
  Future<void> focus() async {}
  Future<void> close() async {}
  Future<void> hide() async {}
  Future<void> minimize() async {}
  Future<void> maximize() async {}
  Future<void> unmaximize() async {}
  Future<void> restore() async {}
  Future<void> center() async {}
  Future<void> setPreventClose(bool value) async {}
  Future<bool> isPreventClose() async => false;
  void addListener(WindowListener listener) {}
  void removeListener(WindowListener listener) {}
  Future<bool> isVisible() async => true;
  Future<bool> isFocused() async => true;
  Future<bool> isMinimized() async => false;
  Future<bool> isMaximized() async => false;
  Future<void> setBounds(dynamic bounds) async {}
  Future<void> getBounds() async {}
  Future<void> setMinimumSize(Size size) async {}
  Future<void> setTitle(String title) async {}
  Future<void> setFullScreen(bool fullScreen) async {}
  Future<void> destroy() async {}
}

final windowManager = WindowManager();

/// 桌面端拖拽移动窗口区域（Web 端退化为普通容器）。
class DragToMoveArea extends StatelessWidget {
  final Widget child;
  const DragToMoveArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

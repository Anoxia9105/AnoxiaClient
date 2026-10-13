import '../../../platform/shims/window_manager_shim.dart';

/// 主窗口关闭策略。标题栏与系统关闭入口统一走原生关闭事件。
mixin DesktopWindowCloseBehavior on WindowListener {
  bool get minimizeToTray;

  Future<void> exitApplication();

  bool _exiting = false;

  @override
  Future<void> onWindowClose() async {
    if (_exiting) return;
    if (minimizeToTray) {
      await windowManager.hide();
    } else {
      _exiting = true;
      try {
        await exitApplication();
      } catch (_) {
        _exiting = false;
        rethrow;
      }
    }
  }

  Future<void> showMainWindow() async {
    // window_manager.show 内部已处理最小化还原，等待显示完成后再聚焦。
    await windowManager.show();
    await windowManager.focus();
  }
}

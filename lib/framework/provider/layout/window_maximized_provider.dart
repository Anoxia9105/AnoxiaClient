import 'package:anoxia/platform/shims/window_manager_shim.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'window_maximized_provider.g.dart';

/// 窗口最大化状态（每个窗口进程各一份，keepAlive 常驻）
///
/// 以窗口真实状态为准做**幂等同步**，而不是按事件翻转（toggle）：
/// - `maximize` / `unmaximize` 事件 → set 为确定值。重复事件、成对事件
///   （最小化后从任务栏还原时插件会补发一次 maximize；跨 DPI 显示器移动、
///   Win11 贴靠可能产生成对事件）都不会造成状态翻转错位。
/// - 首次被 watch 时异步查询一次 `isMaximized()`，覆盖监听注册前已发生的
///   状态变化。
///
/// 背景：此前标题栏按钮图标由 LayoutController.extendedValue 按
/// onWindowMaximize/onWindowUnmaximize 事件翻转驱动，任何一次事件丢失或
/// 重复都会让图标与真实状态脱节——而原生层 Maximize/Unmaximize 对已处于
/// 目标状态的窗口是 no-op，表现为"最大化/还原按钮点了没反应"。
@Riverpod(keepAlive: true)
class WindowMaximized extends _$WindowMaximized with WindowListener {
  @override
  bool build() {
    windowManager.addListener(this);
    ref.onDispose(() => windowManager.removeListener(this));

    // 异步同步一次真实状态：监听注册前窗口可能已经处于最大化
    // （Web 桩返回 false，无害）。
    Future<void>.microtask(() async {
      setMaximized(await windowManager.isMaximized());
    });

    return false;
  }

  /// 幂等同步最大化状态
  void setMaximized(bool value) {
    if (state != value) state = value;
  }

  /// 按当前状态切换最大化/还原
  Future<void> toggle() async {
    if (state) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  void onWindowMaximize() => setMaximized(true);

  @override
  void onWindowUnmaximize() => setMaximized(false);
}

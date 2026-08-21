// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'window_maximized_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(WindowMaximized)
final windowMaximizedProvider = WindowMaximizedProvider._();

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
final class WindowMaximizedProvider
    extends $NotifierProvider<WindowMaximized, bool> {
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
  WindowMaximizedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'windowMaximizedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$windowMaximizedHash();

  @$internal
  @override
  WindowMaximized create() => WindowMaximized();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$windowMaximizedHash() => r'246220ee0a2afda5bbef270c46bf0e5a6d2b7f76';

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

abstract class _$WindowMaximized extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

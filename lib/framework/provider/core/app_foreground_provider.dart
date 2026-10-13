import 'dart:async';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_foreground_provider.g.dart';

/// 桌面窗口可见、聚焦、未最小化且生命周期处于前台时才允许自动已读。
@Riverpod(keepAlive: true)
class AppForeground extends _$AppForeground
    with WidgetsBindingObserver, WindowListener {
  AppLifecycleState? _lifecycle;
  int _revision = 0;
  bool get _resumed =>
      _lifecycle == null || _lifecycle == AppLifecycleState.resumed;

  @override
  bool build() {
    _lifecycle = WidgetsBinding.instance.lifecycleState;
    WidgetsBinding.instance.addObserver(this);
    final desktop = DeviceUtil.isRealDesktop();
    if (desktop) {
      windowManager.addListener(this);
      unawaited(Future<void>.microtask(refresh));
    }
    ref.onDispose(() {
      _revision++;
      WidgetsBinding.instance.removeObserver(this);
      if (desktop) windowManager.removeListener(this);
    });
    return !desktop && _resumed;
  }

  Future<void> refresh() async {
    if (!ref.mounted || !DeviceUtil.isRealDesktop()) return;
    final revision = ++_revision;
    var active = false;
    try {
      final status = await Future.wait([
        windowManager.isVisible(),
        windowManager.isFocused(),
        windowManager.isMinimized(),
      ]);
      active = status[0] && status[1] && !status[2];
    } catch (error) {
      debugLog('读取窗口状态失败，保守保留消息未读: $error');
    }
    if (!ref.mounted || revision != _revision) return;
    state = active && _resumed;
  }

  void _hide() {
    _revision++;
    if (ref.mounted) state = false;
  }

  @override
  void onWindowBlur() => _hide();
  @override
  void onWindowMinimize() => _hide();
  @override
  void onWindowFocus() => unawaited(refresh());
  @override
  void onWindowRestore() => unawaited(refresh());
  @override
  void onWindowEvent(String eventName) {
    if (eventName == 'hide') _hide();
    if (eventName == 'show') unawaited(refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (DeviceUtil.isRealDesktop()) {
      if (_resumed) {
        unawaited(refresh());
      } else {
        _hide();
      }
    } else if (ref.mounted) {
      this.state = _resumed;
    }
  }
}

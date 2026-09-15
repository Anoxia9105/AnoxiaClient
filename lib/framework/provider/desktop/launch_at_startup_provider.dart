import 'package:flutter_riverpod/legacy.dart' as legacy;

import '../../../common/constants/storage_keys.dart';
import '../../../common/utils/sp_util.dart';
import '../../../platform/shims/auto_start_shim.dart';

/// 开机自启动
///
/// 状态以「系统真实状态」为准，本地记录只作为用户意图：
/// - 本地为开启但系统里没有（常见于应用更新后可执行文件路径变化、或用户
///   手动清理了启动项）→ 构造时重新注册一次完成自愈；
/// - 系统里已开启但本地没记录 → 以系统为准回填。
class LaunchAtStartupController extends legacy.StateNotifier<bool> {
  LaunchAtStartupController() : super(_load()) {
    _reconcile();
  }

  static bool _load() =>
      SPUtil.instance.getBool(StorageKeys.launchAtStartup, defValue: false) ?? false;

  Future<void> _reconcile() async {
    if (!autoStartSupported()) return;
    final actual = await autoStartIsEnabled();
    if (actual) {
      _apply(actual);
      return;
    }
    // 系统里没有、但本地记录用户开启过 → 重新注册（路径变化自愈）
    if (state) {
      _apply(await autoStartSetEnabled(true));
    }
  }

  /// 开启/关闭开机自启；系统操作失败时保持原状态，UI 开关自动回弹
  Future<void> setEnabled(bool v) async {
    if (!autoStartSupported()) return;
    _apply(await autoStartSetEnabled(v));
  }

  void _apply(bool v) {
    if (state == v) return;
    state = v;
    SPUtil.instance.setBool(StorageKeys.launchAtStartup, v);
  }
}

final launchAtStartupProvider =
    legacy.StateNotifierProvider<LaunchAtStartupController, bool>(
        (ref) => LaunchAtStartupController());

/// 开机自启后是否隐藏主窗口（仅驻留托盘）
///
/// 依赖开机自启开启才有意义，UI 层负责在关闭开机自启时禁用该项。
class LaunchAtStartupSilentController extends legacy.StateNotifier<bool> {
  LaunchAtStartupSilentController() : super(_load());

  static bool _load() =>
      SPUtil.instance.getBool(StorageKeys.launchAtStartupSilent, defValue: true) ?? true;

  void setEnabled(bool v) {
    if (state == v) return;
    state = v;
    SPUtil.instance.setBool(StorageKeys.launchAtStartupSilent, v);
  }
}

final launchAtStartupSilentProvider =
    legacy.StateNotifierProvider<LaunchAtStartupSilentController, bool>(
        (ref) => LaunchAtStartupSilentController());

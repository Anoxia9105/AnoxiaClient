import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_provider.dart';

/// 解析版本号字符串
///
/// 将 "1.2.3" 转为可比较整数列表，忽略 build number（+xxx）
List<int> _parseVersion(String v) {
  final clean = v.split('+').first.trim();
  return clean.split('.').map((s) => int.tryParse(s.trim()) ?? 0).toList();
}

/// 比较版本号
///
/// 返回 true 表示 a < b
bool _versionLessThan(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  final av = _parseVersion(a);
  final bv = _parseVersion(b);
  final len = av.length > bv.length ? av.length : bv.length;
  for (var i = 0; i < len; i++) {
    final ai = i < av.length ? av[i] : 0;
    final bi = i < bv.length ? bv[i] : 0;
    if (ai < bi) return true;
    if (ai > bi) return false;
  }
  return false;
}

/// 应用更新检查器
///
/// 功能：
/// - 应用启动后延迟 3 秒发起首次检查
/// - 之后每 30 分钟自动重新检查
/// - 保持 keepAlive，贯穿整个应用生命周期
///
/// 支持外部调用：
/// - [forceCheck] 手动触发检查
/// - [syncResult] 同步外部检查结果（避免重复请求）
/// - [dismiss] 清除更新红点
class AppUpdateCheckerNotifier extends Notifier<AppUpdateInfo?> {
  Timer? _timer;

  static const _checkInterval = Duration(minutes: 30);

  @override
  AppUpdateInfo? build() {
    ref.onDispose(() => _timer?.cancel());

    // 启动后延迟 3 秒做首次检查（避免跟启动初始化争抢资源）
    Future.delayed(const Duration(seconds: 3), _check);

    // 定时周期检查
    _timer = Timer.periodic(_checkInterval, (_) => _check());

    return null;
  }

  /// 执行版本检查
  Future<void> _check() async {
    try {
      final currentVersion = await ref.read(appVersionProvider.future);
      final raw = await ref
          .read(settingsRepositoryProvider)
          .checkForUpdate(
            currentVersion: currentVersion,
            clientType: resolveUpdateClientType(),
          );

      // 若当前版本低于 minSupportVersion，强制升级
      final mustForce =
          raw.minSupportVersion.isNotEmpty &&
          _versionLessThan(currentVersion, raw.minSupportVersion);

      final info = mustForce
          ? AppUpdateInfo(
              hasUpdate: true,
              latestVersion: raw.latestVersion,
              currentVersion: raw.currentVersion,
              downloadUrl: raw.downloadUrl,
              releaseNotes: raw.releaseNotes,
              forceUpdate: true,
              minSupportVersion: raw.minSupportVersion,
            )
          : raw;

      state = info.hasUpdate ? info : null;
    } catch (_) {
      // 静默失败，不影响主流程
    }
  }

  /// 手动触发一次检查
  Future<void> forceCheck() => _check();

  /// 同步外部检查结果
  ///
  /// [raw] 外部检查的结果
  /// [currentVersion] 当前版本号
  void syncResult(AppUpdateInfo? raw, {String currentVersion = ''}) {
    if (raw == null || !raw.hasUpdate) {
      state = null;
      return;
    }
    final mustForce =
        raw.minSupportVersion.isNotEmpty &&
        currentVersion.isNotEmpty &&
        _versionLessThan(currentVersion, raw.minSupportVersion);

    state = mustForce
        ? AppUpdateInfo(
            hasUpdate: true,
            latestVersion: raw.latestVersion,
            currentVersion: currentVersion,
            downloadUrl: raw.downloadUrl,
            releaseNotes: raw.releaseNotes,
            forceUpdate: true,
            minSupportVersion: raw.minSupportVersion,
          )
        : raw;
  }

  /// 清除更新红点
  void dismiss() => state = null;
}

/// 版本检查 Provider
final appUpdateCheckerProvider =
    NotifierProvider<AppUpdateCheckerNotifier, AppUpdateInfo?>(
      AppUpdateCheckerNotifier.new,
    );

/// 是否有新版本（用于 badge 判断）
final hasAppUpdateProvider = Provider<bool>(
  (ref) => ref.watch(appUpdateCheckerProvider) != null,
);

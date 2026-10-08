import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pub_semver/pub_semver.dart';

import '../core/network_provider.dart';
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

/// 版本号归一化（与服务端 normalizeVersion 对齐）
///
/// 去掉 v 前缀、build number（+xxx）与预发布后缀（-xxx），
/// 避免 "2.3.6+28 > 2.3.6" 这类 semver build 比较误判。
String _normalizeVersion(String v) {
  var s = v.trim();
  if (s.isEmpty) return '';
  if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
  final plus = s.indexOf('+');
  if (plus > -1) s = s.substring(0, plus);
  final dash = s.indexOf('-');
  if (dash > -1) s = s.substring(0, dash);
  return s.trim();
}

/// 客户端兜底版本比较：latest 是否高于 current
///
/// 服务端 hasUpdate 不可信（如管理端把版本号填错）时，
/// 客户端按归一化后的 semver 再比较一次；解析失败则只信服务端结果。
bool _isNewerThan(String latest, String current) {
  final l = _normalizeVersion(latest);
  final c = _normalizeVersion(current);
  if (l.isEmpty || c.isEmpty) return false;
  try {
    return Version.parse(l) > Version.parse(c);
  } catch (_) {
    return false;
  }
}

/// 应用更新检查器
///
/// 功能：
/// - 应用启动后延迟 3 秒发起首次检查（可被 [checkNow] 抢先，避免重复请求）
/// - 之后每 30 分钟自动重新检查
/// - 网络从离线恢复时补一次检查（5 分钟防抖）
/// - 保持 keepAlive，贯穿整个应用生命周期
///
/// 支持外部调用：
/// - [checkNow] 立即执行一次检查并返回结果（供启动流程/手动刷新使用）
/// - [forceCheck] 手动触发检查（兼容旧入口）
/// - [syncResult] 同步外部检查结果（避免重复请求）
/// - [dismiss] 清除更新红点
class AppUpdateCheckerNotifier extends Notifier<AppUpdateInfo?> {
  Timer? _timer;
  Timer? _initialTimer;

  static const _checkInterval = Duration(minutes: 30);

  /// 网络恢复后补查的最小间隔（防止连接抖动导致频繁请求）
  static const _networkRetryDebounce = Duration(minutes: 5);

  /// 如果外部已经通过 [syncResult] / [checkNow] 提前完成了检查，
  /// 跳过即将到来的首次定时检查
  bool _skipNextScheduledCheck = false;

  /// 是否有检查正在进行（防止轮询/网络恢复/手动检查并发重复请求）
  bool _inFlight = false;

  /// 上次成功发起检查的时间（网络恢复防抖用）
  DateTime _lastCheckAt = DateTime.now();

  @override
  AppUpdateInfo? build() {
    ref.onDispose(() {
      _timer?.cancel();
      _initialTimer?.cancel();
    });

    // 启动后延迟 3 秒做首次检查（避免跟启动初始化争抲资源）
    // 用可取消的 Timer（而非 Future.delayed），否则 dispose 后仍有 pending timer，
    // 在 widget 测试里会触发「A Timer is still pending」失败。
    _initialTimer = Timer(
      const Duration(seconds: 3),
      () => unawaited(_scheduledInitialCheck()),
    );

    // 定时周期检查
    _timer = Timer.periodic(_checkInterval, (_) => _check());

    // 网络从离线恢复：补一次防抖检查（冷启动时网络未就绪导致首查失败的场景）
    ref.listen(networkStatusProvider, (previous, next) {
      final statuses = next.value;
      if (statuses == null) return;
      final online = !statuses.contains(ConnectivityResult.none);
      final prevStatuses = previous?.value;
      final wasOnline = prevStatuses != null &&
          !prevStatuses.contains(ConnectivityResult.none);
      if (online && !wasOnline) {
        unawaited(onNetworkRestored());
      }
    });

    return null;
  }

  /// 首次延迟检查：若外部已提前填充结果则跳过
  Future<void> _scheduledInitialCheck() async {
    if (_skipNextScheduledCheck) {
      _skipNextScheduledCheck = false;
      return;
    }
    await _check();
  }

  /// 执行版本检查
  ///
  /// 返回检查结果（有更新时非 null），供启动流程判断是否强更。
  Future<AppUpdateInfo?> _check() async {
    // 并发防抖：已有检查在途时直接返回当前状态
    if (_inFlight) return state;
    _inFlight = true;
    _lastCheckAt = DateTime.now();
    try {
      final currentVersion = await ref.read(appVersionProvider.future);
      final raw = await ref
          .read(settingsRepositoryProvider)
          .checkForUpdate(
            currentVersion: currentVersion,
            clientType: resolveUpdateClientType(),
          );

      // 客户端兜底：服务端 hasUpdate 或版本号填写异常时，本地再比较一次
      final hasUpdate =
          raw.hasUpdate || _isNewerThan(raw.latestVersion, currentVersion);

      if (!hasUpdate) {
        state = null;
        return null;
      }

      // 若当前版本低于 minSupportVersion，强制升级
      final mustForce =
          raw.minSupportVersion.isNotEmpty &&
          _versionLessThan(currentVersion, raw.minSupportVersion);

      final info = AppUpdateInfo(
        hasUpdate: true,
        latestVersion: raw.latestVersion,
        currentVersion: currentVersion,
        downloadUrl: raw.downloadUrl,
        releaseNotes: raw.releaseNotes,
        forceUpdate: raw.forceUpdate || mustForce,
        minSupportVersion: raw.minSupportVersion,
        fileSize: raw.fileSize,
        fileHash: raw.fileHash,
      );

      state = info;
      return info;
    } catch (_) {
      // 静默失败，不影响主流程（轮询/网络恢复会重试）
      return null;
    } finally {
      _inFlight = false;
    }
  }

  /// 立即执行一次检查并返回结果
  ///
  /// 供 main.dart 启动流程调用（带外部超时保护）：
  /// 若 3s 延迟首查尚未执行，会被本次检查顶替，避免重复请求。
  Future<AppUpdateInfo?> checkNow() {
    _skipNextScheduledCheck = true;
    return _check();
  }

  /// 手动触发一次检查（兼容旧入口）
  Future<void> forceCheck() => _check();

  /// 网络从离线恢复：距上次检查超过防抖窗口才补查
  Future<void> onNetworkRestored() async {
    if (_inFlight) return;
    if (DateTime.now().difference(_lastCheckAt) < _networkRetryDebounce) {
      return;
    }
    await _check();
  }

  /// 同步外部检查结果（同时标记跳过即将的首次延迟检查，避免重复请求）
  ///
  /// [raw] 外部检查的结果
  /// [currentVersion] 当前版本号
  void syncResult(AppUpdateInfo? raw, {String currentVersion = ''}) {
    _skipNextScheduledCheck = true; // 取消 build() 里挂的 3s 延迟重复检查
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
            fileSize: raw.fileSize,
            fileHash: raw.fileHash,
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

import 'dart:async';
import 'dart:convert';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/features/update/domain/update_download_target.dart';
import 'package:anoxia/framework/core/notification_helper.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/platform/shims/app_exit_shim.dart';
// Windows 桌面安装前需隐藏主窗口（shim 条件导出，Web 编译安全）
import 'package:anoxia/platform/shims/window_manager_shim.dart' as desktop;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import 'general_settings_provider.dart';
import 'settings_provider.dart';
import 'update_check_provider.dart';
import 'update_package_file_helper.dart';

/// 更新安装包下载完成通知的固定 ID（避免与消息通知冲突）
const int kUpdateReadyNotificationId = 990001;

/// 下载阶段
enum UpdateDownloadPhase { idle, downloading, ready, failed }

/// 更新下载状态（不可变快照，UI 直接 watch）
@immutable
class UpdateDownloadState {
  final UpdateDownloadPhase phase;

  /// 目标版本号
  final String version;

  /// 目标下载地址
  final String url;

  /// 就绪后的安装包本地路径（[UpdateDownloadPhase.ready] 时有效）
  final String filePath;

  /// 下载进度 0..1
  final double progress;
  final int receivedBytes;
  final int totalBytes;

  /// 失败原因（i18n key 或兜底文案）
  final String errorMessage;

  /// 「已就绪」横幅是否被用户手动关闭
  final bool bannerDismissed;

  const UpdateDownloadState({
    this.phase = UpdateDownloadPhase.idle,
    this.version = '',
    this.url = '',
    this.filePath = '',
    this.progress = 0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage = '',
    this.bannerDismissed = false,
  });

  bool get isBusy => phase == UpdateDownloadPhase.downloading;

  UpdateDownloadState copyWith({
    UpdateDownloadPhase? phase,
    String? version,
    String? url,
    String? filePath,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    String? errorMessage,
    bool? bannerDismissed,
  }) {
    return UpdateDownloadState(
      phase: phase ?? this.phase,
      version: version ?? this.version,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      bannerDismissed: bannerDismissed ?? this.bannerDismissed,
    );
  }
}

/// 更新安装包后台静默下载控制器
///
/// 功能：
/// - 监听 [appUpdateCheckerProvider]：发现新版本且满足策略时自动后台下载
///   （默认仅 Wi-Fi/以太网；移动流量需用户在设置中开启）；
/// - 下载完成后进入 [UpdateDownloadPhase.ready]，发系统通知 + 应用内横幅，
///   用户点击即可直接安装（Android 拉起 APK 安装器 / Windows 运行安装程序）；
/// - 下载中服务端又发布更新版本时，自动取消当前任务重新下载；
/// - 下载完成校验文件大小与 SHA-256（服务端下发时）；
/// - 启动/下载前清理更新目录残留安装包。
///
/// 平台策略：
/// - Web：不支持（直接跳过）；
/// - iOS：不能旁加载安装包，不自动下载，仍走应用商店/浏览器路径；
/// - Android / Windows / macOS / Linux：支持静默下载 + 就绪安装。
class UpdateDownloadController extends Notifier<UpdateDownloadState> {
  CancelToken? _cancelToken;

  /// 当前任务标识（"version|url"），用于幂等去重
  String _activeKey = '';

  /// 进度上报节流（每 1% 或 256KB 才更新一次 state，避免重建风暴）
  int _lastNotifiedBytes = 0;

  @override
  UpdateDownloadState build() {
    ref.onDispose(() {
      _cancelToken?.cancel('provider disposed');
      _cancelToken = null;
    });

    // 监听版本检查结果：发现新版本 → 按策略自动后台下载
    ref.listen<AppUpdateInfo?>(appUpdateCheckerProvider, (previous, next) {
      final info = next;
      if (info == null || !info.hasUpdate) return;
      unawaited(maybeAutoDownload(info));
    });

    // provider 创建时检查结果可能已经就绪（如启动期 checkNow 先行完成）
    final existing = ref.read(appUpdateCheckerProvider);
    if (existing != null && existing.hasUpdate) {
      unawaited(maybeAutoDownload(existing));
    }

    return const UpdateDownloadState();
  }

  /// 按策略判断是否自动下载；不满足条件时静默跳过（用户仍可手动触发）
  Future<void> maybeAutoDownload(AppUpdateInfo info) async {
    if (DeviceUtil.isRealWeb()) return;
    // iOS 无法旁加载安装包，保持应用商店/浏览器路径
    if (defaultTargetPlatform == TargetPlatform.iOS) return;
    if (!ref.read(autoDownloadUpdateProvider)) return;
    if (!await _networkAllowed()) return;
    await startDownload(info);
  }

  /// 当前网络是否允许自动下载
  Future<bool> _networkAllowed() async {
    // 用户允许流量下载时不再探测网络类型
    if (ref.read(updateCellularDownloadProvider)) return true;
    try {
      final results = await Connectivity()
          .checkConnectivity()
          .timeout(const Duration(seconds: 3));
      return results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
    } catch (_) {
      // 探测失败按保守策略：不自动下载
      return false;
    }
  }

  /// 开始（或重新开始）下载安装包
  ///
  /// 手动触发（更新页/横幅重试）与自动触发共用入口；同版本在途或已就绪时幂等返回。
  Future<void> startDownload(AppUpdateInfo info) async {
    if (DeviceUtil.isRealWeb()) return;

    final key = '${info.latestVersion}|${info.downloadUrl}';
    if (state.isBusy && _activeKey == key) return; // 同目标正在下载
    if (state.phase == UpdateDownloadPhase.ready &&
        state.version == info.latestVersion &&
        state.filePath.isNotEmpty) {
      return; // 同版本已就绪
    }

    UpdateDownloadTarget target;
    try {
      target = UpdateDownloadTarget.parse(info.downloadUrl);
    } on FormatException {
      state = UpdateDownloadState(
        phase: UpdateDownloadPhase.failed,
        version: info.latestVersion,
        errorMessage: 'update_error_invalid_url',
      );
      return;
    }

    final String dir;
    try {
      dir = await resolveUpdateSaveDir();
    } catch (e) {
      debugLog('解析更新保存目录失败: $e');
      state = UpdateDownloadState(
        phase: UpdateDownloadPhase.failed,
        version: info.latestVersion,
        errorMessage: 'update_error_generic_safe',
      );
      return;
    }

    final fileName = _targetFileName(target.fileName, info.latestVersion);
    final savePath = p.join(dir, fileName);

    // 版本切换或重下：先取消在途任务
    await _cancelInflight();

    // 清理旧版本残留（保留本次目标文件）
    unawaited(cleanupUpdateFiles(dir, keepName: fileName));

    _activeKey = key;
    _lastNotifiedBytes = 0;
    final token = CancelToken();
    _cancelToken = token;

    state = UpdateDownloadState(
      phase: UpdateDownloadPhase.downloading,
      version: info.latestVersion,
      url: info.downloadUrl,
      totalBytes: info.fileSize,
    );

    try {
      await DioClient().download(
        info.downloadUrl,
        savePath,
        cancelToken: token,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          _emitProgress(received, total);
        },
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        // 主动取消：回到 idle，等新版本任务接管
        _activeKey = '';
        state = const UpdateDownloadState();
        return;
      }
      debugLog('更新安装包下载失败: $e');
      _activeKey = '';
      state = UpdateDownloadState(
        phase: UpdateDownloadPhase.failed,
        version: info.latestVersion,
        errorMessage: _mapDownloadError(e),
      );
      return;
    } catch (e) {
      debugLog('更新安装包下载异常: $e');
      _activeKey = '';
      state = UpdateDownloadState(
        phase: UpdateDownloadPhase.failed,
        version: info.latestVersion,
        errorMessage: 'update_error_generic_safe',
      );
      return;
    }

    // —— 完整性校验 ——
    final actualLength = await updateFileLength(savePath);
    if (actualLength <= 0) {
      _activeKey = '';
      state = UpdateDownloadState(
        phase: UpdateDownloadPhase.failed,
        version: info.latestVersion,
        errorMessage: 'update_error_generic_safe',
      );
      return;
    }
    if (info.fileSize > 0 && actualLength != info.fileSize) {
      debugLog('安装包大小校验失败: 期望 ${info.fileSize}，实际 $actualLength');
      await _deleteQuietly(savePath);
      _activeKey = '';
      state = UpdateDownloadState(
        phase: UpdateDownloadPhase.failed,
        version: info.latestVersion,
        errorMessage: 'update_error_generic_safe',
      );
      return;
    }
    if (info.fileHash.isNotEmpty) {
      final actualHash = await updateFileSha256Hex(savePath);
      if (actualHash.isEmpty ||
          !actualHash.toLowerCase().endsWith(info.fileHash.toLowerCase())) {
        debugLog('安装包 SHA-256 校验失败: 期望 ${info.fileHash}，实际 $actualHash');
        await _deleteQuietly(savePath);
        _activeKey = '';
        state = UpdateDownloadState(
          phase: UpdateDownloadPhase.failed,
          version: info.latestVersion,
          errorMessage: 'update_error_generic_safe',
        );
        return;
      }
    }

    _activeKey = '';
    state = UpdateDownloadState(
      phase: UpdateDownloadPhase.ready,
      version: info.latestVersion,
      url: info.downloadUrl,
      filePath: savePath,
      progress: 1,
      receivedBytes: actualLength,
      totalBytes: actualLength,
    );

    unawaited(_notifyReady(info));

    // 强制更新：下载完成直接拉起安装器，不留「稍后」
    if (info.forceUpdate) {
      unawaited(installReadyUpdate());
    }
  }

  /// 安装已就绪的更新包
  ///
  /// Android 先补一次「安装未知应用」权限申请，再通过 open_filex 拉起系统安装器；
  /// Windows 运行安装程序并按既有约定隐藏窗口 + 退出进程。
  /// 返回是否成功拉起（用户拒绝授权/启动失败返回 false，UI 可提示重试）。
  Future<bool> installReadyUpdate() async {
    final path = state.filePath;
    if (path.isEmpty) return false;

    if (DeviceUtil.isAndroid()) {
      try {
        final status = await Permission.requestInstallPackages.status;
        if (!status.isGranted) {
          final result = await Permission.requestInstallPackages.request();
          if (!result.isGranted) {
            debugLog('用户未授予「安装未知应用」权限，取消安装');
            return false;
          }
        }
      } catch (e) {
        debugLog('安装权限申请失败（继续尝试拉起安装器）: $e');
      }
    }

    try {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        debugLog('启动安装器失败: ${result.message}');
        return false;
      }
      if (DeviceUtil.isRealDesktop()) {
        await desktop.windowManager.hide();
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await terminateAppProcess();
      }
      return true;
    } catch (e) {
      debugLog('安装更新失败: $e');
      return false;
    }
  }

  /// 关闭「已就绪」横幅（系统通知保留）
  void dismissBanner() {
    if (state.bannerDismissed) return;
    state = state.copyWith(bannerDismissed: true);
  }

  /// 清空状态（版本切换/测试用）
  void reset() {
    unawaited(_cancelInflight());
    state = const UpdateDownloadState();
  }

  /// 目标文件名：URL 文件名已含版本号则沿用，否则加版本前缀便于残留清理
  String _targetFileName(String originalName, String version) {
    final v = version.trim().split('+').first.trim();
    if (v.isEmpty || originalName.toLowerCase().contains(v.toLowerCase())) {
      return originalName;
    }
    return 'Anoxia-$v-$originalName';
  }

  /// 进度上报（节流：字节增量 >= 256KB 或首次回调时才更新 state）
  void _emitProgress(int received, int total) {
    if (total <= 0) return;
    if (_lastNotifiedBytes != 0 && received - _lastNotifiedBytes < 256 * 1024) {
      return;
    }
    _lastNotifiedBytes = received;
    if (!state.isBusy) return;
    state = state.copyWith(
      progress: (received / total).clamp(0.0, 1.0),
      receivedBytes: received,
      totalBytes: total,
    );
  }

  /// 取消在途下载任务
  Future<void> _cancelInflight() async {
    final token = _cancelToken;
    _cancelToken = null;
    if (token == null) return;
    if (!token.isCancelled) {
      token.cancel('superseded by a newer update download');
    }
  }

  /// 下载错误 → i18n key
  String _mapDownloadError(DioException e) {
    final code = e.response?.statusCode;
    if (code == 404) return 'update_error_404';
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'update_error_network';
    }
    return 'update_error_generic_safe';
  }

  /// 就绪提示：系统通知（桌面端窗口聚焦时 NotificationHelper 内部自动跳过，
  /// 移动端始终弹出）+ 应用内横幅由 UI watch state 自行渲染。
  Future<void> _notifyReady(AppUpdateInfo info) async {
    if (DeviceUtil.isRealWeb()) return;
    try {
      await NotificationHelper().show(
        id: kUpdateReadyNotificationId,
        title: 'update_ready_notify_title'.tr(args: [info.latestVersion]),
        body: 'update_ready_notify_body'.tr(),
        payload: jsonEncode(<String, dynamic>{'kind': 'update_install'}),
      );
    } catch (e) {
      debugLog('发送更新就绪通知失败: $e');
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await deleteUpdateFile(path);
    } catch (_) {}
  }
}

/// 更新下载状态 Provider（keepAlive，贯穿应用生命周期）
final updateDownloadControllerProvider =
    NotifierProvider<UpdateDownloadController, UpdateDownloadState>(
      UpdateDownloadController.new,
    );

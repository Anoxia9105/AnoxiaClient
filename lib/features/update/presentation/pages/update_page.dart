import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:anoxia/framework/provider/setting/update_download_provider.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/features/update/domain/update_download_target.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/platform/shims/app_exit_shim.dart';
// AppUpdateInfo 由 settings_provider.dart 显式 re-export，无需再单独引入 domain 文件
// （同时这里还需要 appVersionProvider 读取当前版本号）
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';
import '../widgets/update_sections.dart';

/// 应用更新页面
///
/// 显示应用更新信息、下载进度，并支持更新安装。
///
/// 注意：本页会在两种宿主中出现——
/// 1. GoRouter 的 [UpdateRoute] 页面路由（设置页/官方号主动检查进入）；
/// 2. 强制更新时由 main.dart 通过 `runApp` 直接挂载的独立更新窗口，
///    此时整棵树里**没有 GoRouter、也没有可返回的路由栈**。
///
/// 因此本页严禁使用 `context.canPop()` / `context.pop()` 这类 GoRouter 扩展
/// （会抛 `No GoRouter found in context`），一律改用 Navigator 的安全写法。
class UpdatePage extends ConsumerStatefulWidget {
  /// 更新信息对象
  final AppUpdateInfo updateInfo;

  /// 是否以独立更新窗口方式启动（无路由栈可返回，需要提供退出入口）
  final bool standalone;

  const UpdatePage({
    super.key,
    required this.updateInfo,
    this.standalone = false,
  });

  @override
  ConsumerState<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends ConsumerState<UpdatePage> {
  /// 下载进度（0-1）
  double _progress = 0;

  /// 是否正在下载
  bool _isDownloading = false;

  /// 是否已经开始下载
  bool _hasStarted = false;

  /// 是否已跳转浏览器（移动端外部下载）
  bool _openedInBrowser = false;

  /// 错误信息
  String? _error;
  bool _downloadFinished = false;

  /// 是否为强制更新
  bool get _isForceUpdate => widget.updateInfo.forceUpdate;

  /// 是否支持应用内下载安装（Android / Windows / macOS / Linux）
  ///
  /// 这些平台走 [UpdateDownloadController]：后台静默下载 + 就绪一键安装；
  /// iOS / Web 仍走系统浏览器/应用商店路径。
  bool get _useInAppDownload =>
      !DeviceUtil.isRealWeb() && !DeviceUtil.isIOS();

  Future<void> _startDownload() async {
    // 应用内下载：交给全局下载控制器（后台静默下载 + 完整性校验）
    if (_useInAppDownload) {
      setState(() {
        _hasStarted = true;
        _error = null;
      });
      unawaited(
        ref
            .read(updateDownloadControllerProvider.notifier)
            .startDownload(widget.updateInfo),
      );
      return;
    }

    UpdateDownloadTarget target;
    try {
      target = UpdateDownloadTarget.parse(widget.updateInfo.downloadUrl);
    } on FormatException {
      setState(() => _error = 'update_error_invalid_url'.tr());
      return;
    }

    setState(() {
      _isDownloading = true;
      _hasStarted = true;
      _error = null;
      _openedInBrowser = false;
      _downloadFinished = false;
    });

    try {
      if (DeviceUtil.isRealMobile() || DeviceUtil.isRealWeb()) {
        final launched = await launchUrl(
          target.uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          throw Exception('cannot open update url');
        }

        if (!mounted) return;
        setState(() {
          _isDownloading = false;
          _progress = 0;
          _openedInBrowser = true;
        });
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final savePath = path.join(tempDir.path, target.fileName);

      final response = await DioClient().download(
        widget.updateInfo.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            if (!mounted) return;
            setState(() {
              _progress = (received / total).clamp(0, 1);
            });
          }
        },
      );

      final statusCode = response.statusCode;
      if (statusCode == null || statusCode < 200 || statusCode >= 300) {
        throw Exception('服务器响应异常: ${response.statusCode}');
      }

      if (mounted) {
        setState(() {
          _progress = 1;
          _downloadFinished = true;
        });
      }
      final result = await OpenFilex.open(savePath);

      if (result.type == ResultType.done) {
        if (DeviceUtil.isRealDesktop()) {
          await windowManager.hide();
        }

        await Future.delayed(const Duration(milliseconds: 500));
        await terminateAppProcess();
      } else {
        throw Exception('无法启动安装包: ${result.message}');
      }
    } catch (e) {
      debugLog('❌ 更新失败: $e');
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _error = _formatError(e);
      });
    }
  }

  String _formatError(dynamic e) {
    final s = e.toString();
    if (s.contains('404')) return 'update_error_404'.tr();
    if (s.contains('SocketException')) return 'update_error_network'.tr();
    if (s.contains('cannot open update url')) {
      return 'update_error_open_browser'.tr();
    }
    if (s.contains('无法启动安装包')) {
      return 'update_error_open_installer'.tr();
    }
    return 'update_error_generic_safe'.tr();
  }

  List<String> _releaseNoteLines() {
    final raw = widget.updateInfo.releaseNotes.trim();
    final source = raw.isEmpty ? 'update_default_notes'.tr() : raw;
    return source
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// 当前版本号：更新信息里没有时回落到包信息（去掉 build number）
  String _resolveCurrentVersion() {
    final fromInfo = widget.updateInfo.currentVersion.trim();
    String raw = fromInfo;
    if (raw.isEmpty) {
      final asyncVersion = ref.watch(appVersionProvider);
      raw = asyncVersion.hasValue ? (asyncVersion.value ?? '') : '';
    }
    return raw.split('+').first.trim();
  }

  /// 返回上一页
  ///
  /// 不依赖 GoRouter：既能用在路由页（GoRouter 的 Navigator 会同步 URL），
  /// 也能在没有 GoRouter 的独立更新窗口里安全执行（此时 canPop 为 false）。
  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  /// 退出应用（强制更新且无路可退时给用户一个明确出口）
  Future<void> _exitApp() async {
    if (DeviceUtil.isRealDesktop()) {
      try {
        await windowManager.setPreventClose(false);
        await windowManager.close();
        return;
      } catch (e) {
        debugLog('❌ 关闭窗口失败，直接退出: $e');
      }
    } else if (DeviceUtil.isRealMobile()) {
      if (DeviceUtil.isAndroid()) {
        await const MethodChannel(
          'app_navigation',
        ).invokeMethod<void>('exitApp');
      } else {
        await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
      }
      return;
    }
    await terminateAppProcess();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 560;
    final notes = _releaseNoteLines();
    final currentVersion = _resolveCurrentVersion();

    // 应用内下载（Android/桌面）：镜像全局下载控制器状态
    final dlState = _useInAppDownload
        ? ref.watch(updateDownloadControllerProvider)
        : null;
    final dlMatches =
        dlState != null && dlState.version == widget.updateInfo.latestVersion;
    final dlDownloading =
        dlMatches && dlState.phase == UpdateDownloadPhase.downloading;
    final dlReady =
        dlMatches && dlState.phase == UpdateDownloadPhase.ready;
    final dlFailed = dlMatches && dlState.phase == UpdateDownloadPhase.failed;

    final effectiveDownloading = _isDownloading || dlDownloading;
    final effectiveProgress = dlDownloading
        ? dlState.progress
        : _progress;
    final String? effectiveError = dlFailed
        ? (dlState.errorMessage.isNotEmpty
              ? dlState.errorMessage.tr()
              : 'update_error_generic_safe'.tr())
        : _error;

    // standalone 时整棵树是 runApp 重建的独立更新窗口，无上层路由可返回
    final canGoBack =
        !_isForceUpdate && !widget.standalone && Navigator.of(context).canPop();

    return AppScaffold(
      // 独立更新窗口里没有完整业务上下文，禁用全局搜索热键（Ctrl/Cmd+K）
      enableGlobalSearchHotkey: false,
      hideAppBarLogo: true,
      title: Text('update_title'.tr()),
      body: PopScope(
        canPop: !_isForceUpdate,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? SpacingToken.lg : SpacingToken.xl,
                vertical: SpacingToken.xxl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (canGoBack) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _goBack,
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowLeft01,
                            size: 18,
                          ),
                          label: Text('common_back'.tr()),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacingToken.md,
                              vertical: SpacingToken.xs,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: SpacingToken.sm),
                    ],
                    UpdateHeroCard(
                      currentVersion: currentVersion,
                      latestVersion: widget.updateInfo.latestVersion,
                      isForceUpdate: _isForceUpdate,
                    ),
                    const SizedBox(height: SpacingToken.lg),
                    UpdateReleaseNotesCard(notes: notes),
                    const SizedBox(height: SpacingToken.lg),
                    UpdateActionArea(
                      isDownloading: effectiveDownloading,
                      hasStarted: _hasStarted,
                      openedInBrowser: _openedInBrowser,
                      progress: effectiveProgress,
                      downloadFinished: _downloadFinished,
                      isReady: dlReady,
                      onInstall: () => ref
                          .read(updateDownloadControllerProvider.notifier)
                          .installReadyUpdate(),
                      onStartDownload: _startDownload,
                    ),
                    if (effectiveError != null && !effectiveDownloading) ...[
                      const SizedBox(height: SpacingToken.md),
                      // effectiveError 已被条件判空提升为非空，无需再断言
                      UpdateErrorCard(message: effectiveError),
                    ],
                    const SizedBox(height: SpacingToken.lg),
                    if (_isForceUpdate)
                      // 强制更新：没有「稍后再说」，独立窗口下提供退出入口
                      Center(
                        child: TextButton.icon(
                          onPressed: _exitApp,
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedLogout03,
                            size: 16,
                          ),
                          label: Text('update_exit_app'.tr()),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacingToken.lg,
                              vertical: SpacingToken.sm,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                RadiusToken.pill,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: TextButton(
                          onPressed: _goBack,
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacingToken.lg,
                              vertical: SpacingToken.sm,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                RadiusToken.pill,
                              ),
                            ),
                          ),
                          child: Text('update_later'.tr()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/features/update/domain/update_download_target.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:anoxia/framework/provider/setting/update_download_provider.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';
import 'package:anoxia/platform/shims/app_exit_shim.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/update_sections.dart';

/// 更新页兼容设置路由和无 GoRouter 的强制更新窗口。
class UpdatePage extends ConsumerStatefulWidget {
  const UpdatePage({
    super.key,
    required this.updateInfo,
    this.standalone = false,
  });
  final AppUpdateInfo updateInfo;
  final bool standalone;
  @override
  ConsumerState<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends ConsumerState<UpdatePage> {
  bool _hasStarted = false;
  bool _opening = false;
  bool _openedInBrowser = false;
  bool _installing = false;
  bool _confirming = false;
  String? _error;
  bool get _isForceUpdate => widget.updateInfo.forceUpdate;
  bool get _useInAppDownload => !DeviceUtil.isRealWeb() && !DeviceUtil.isIOS();

  Future<void> _startDownload() async {
    if (_opening) return;
    setState(() {
      _hasStarted = true;
      _error = null;
    });
    if (_useInAppDownload) {
      unawaited(
        ref
            .read(updateDownloadControllerProvider.notifier)
            .startDownload(widget.updateInfo),
      );
      return;
    }
    setState(() => _opening = true);
    try {
      final target = UpdateDownloadTarget.parse(widget.updateInfo.downloadUrl);
      if (!await launchUrl(target.uri, mode: LaunchMode.externalApplication)) {
        throw StateError('cannot open update url');
      }
      if (mounted) setState(() => _openedInBrowser = true);
    } on FormatException {
      if (mounted) setState(() => _error = 'update_error_invalid_url'.tr());
    } catch (error) {
      debugLog('打开更新地址失败: $error');
      if (mounted) setState(() => _error = 'update_error_open_browser'.tr());
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _install() async {
    if (_installing || _confirming) return;
    _confirming = true;
    final heading = 'update_install_confirm_title'.tr(
      args: [widget.updateInfo.latestVersion],
    );
    final message = 'update_install_confirm_body'.tr();
    try {
      final bool? confirmed;
      if (MediaQuery.sizeOf(context).width < 650) {
        confirmed = await showModalBottomSheet<bool>(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          builder: (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(SpacingToken.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    heading,
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: SpacingToken.lg),
                  Text(message),
                  const SizedBox(height: SpacingToken.xl),
                  FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: Text('update_install_continue'.tr()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: Text('dialog_cancel'.tr()),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(heading),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('dialog_cancel'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text('update_install_continue'.tr()),
              ),
            ],
          ),
        );
      }
      if (!mounted || confirmed != true) return;
      setState(() => _installing = true);
      final controller = ref.read(updateDownloadControllerProvider.notifier);
      final state = ref.read(updateDownloadControllerProvider);
      if (!_matches(state) || state.phase != UpdateDownloadPhase.ready) return;
      if (!await controller.installReadyUpdate() && mounted) {
        setState(() => _error = 'update_error_open_installer'.tr());
      }
    } finally {
      _confirming = false;
      if (mounted) setState(() => _installing = false);
    }
  }

  bool _matches(UpdateDownloadState state) =>
      state.version == widget.updateInfo.latestVersion &&
      state.url == widget.updateInfo.downloadUrl;
  void _goBack() {
    final navigator = Navigator.of(context);
    if (!_isForceUpdate && navigator.canPop()) navigator.pop();
  }

  Future<void> _exitApp() async {
    if (DeviceUtil.isRealDesktop()) {
      try {
        await windowManager.setPreventClose(false);
        await windowManager.close();
        return;
      } catch (error) {
        debugLog('关闭更新窗口失败: $error');
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
    final cs = theme.colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 650;
    final state = _useInAppDownload
        ? ref.watch(updateDownloadControllerProvider)
        : null;
    final matches = state != null && _matches(state);
    final downloading =
        matches && state.phase == UpdateDownloadPhase.downloading;
    final paused = matches && state.phase == UpdateDownloadPhase.paused;
    final ready = matches && state.phase == UpdateDownloadPhase.ready;
    final failed = matches && state.phase == UpdateDownloadPhase.failed;
    final error =
        _error ??
        (failed
            ? (state.errorMessage.isEmpty
                      ? 'update_error_generic_safe'
                      : state.errorMessage)
                  .tr()
            : null);
    final current = widget.updateInfo.currentVersion.isNotEmpty
        ? widget.updateInfo.currentVersion
        : ref.watch(appVersionProvider).value ?? '';
    final rawNotes = widget.updateInfo.releaseNotes.trim();
    final notes = (rawNotes.isEmpty ? 'update_default_notes'.tr() : rawNotes)
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final canGoBack =
        !_isForceUpdate && !widget.standalone && Navigator.of(context).canPop();
    return AppScaffold(
      enableGlobalSearchHotkey: false,
      hideAppBarLogo: true,
      title: Text('update_title'.tr()),
      body: ColoredBox(
        color: cs.surface,
        child: PopScope(
          canPop: !_isForceUpdate,
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  compact ? SpacingToken.xl : SpacingToken.xxl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (canGoBack) ...[
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: _goBack,
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowLeft01,
                              size: 18,
                            ),
                            label: Text('settings_page_about_title'.tr()),
                          ),
                        ),
                        const SizedBox(height: SpacingToken.xl),
                      ],
                      UpdateHeroCard(
                        currentVersion: current.split('+').first,
                        latestVersion: widget.updateInfo.latestVersion,
                        isForceUpdate: _isForceUpdate,
                      ),
                      const SizedBox(height: SpacingToken.xl),
                      UpdateActionArea(
                        isDownloading: downloading || _opening,
                        isPaused: paused,
                        hasStarted: _hasStarted,
                        openedInBrowser: _openedInBrowser,
                        downloadFinished: false,
                        isReady: ready,
                        installing: _installing,
                        progress: matches ? state.progress : 0,
                        receivedBytes: matches ? state.receivedBytes : 0,
                        totalBytes: matches && state.totalBytes > 0
                            ? state.totalBytes
                            : widget.updateInfo.fileSize,
                        errorMessage: error,
                        onStartDownload: _startDownload,
                        onInstall: _install,
                        onPause: _useInAppDownload
                            ? ref
                                  .read(
                                    updateDownloadControllerProvider.notifier,
                                  )
                                  .pauseDownload
                            : null,
                        onResume: _useInAppDownload
                            ? ref
                                  .read(
                                    updateDownloadControllerProvider.notifier,
                                  )
                                  .resumeDownload
                            : null,
                      ),
                      const SizedBox(height: SpacingToken.xxl),
                      UpdateReleaseNotesCard(notes: notes),
                      const SizedBox(height: SpacingToken.lg),
                      Divider(color: cs.outlineVariant.withValues(alpha: .5)),
                      const SizedBox(height: SpacingToken.md),
                      Text(
                        'update_install_footnote'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.7,
                        ),
                      ),
                      if (_isForceUpdate)
                        TextButton.icon(
                          onPressed: _exitApp,
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedLogout03,
                            size: 16,
                          ),
                          label: Text('update_exit_app'.tr()),
                        )
                      else if (canGoBack && !downloading && !paused)
                        TextButton(
                          onPressed: _goBack,
                          child: Text('update_later'.tr()),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

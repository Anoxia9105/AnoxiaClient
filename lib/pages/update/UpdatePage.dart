import 'dart:io';

import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../common/utils/DeviceUtil.dart';
import '../../framework/network/DioClient.dart';
import '../../framework/provider/core/AppUpdateInfo.dart';
import '../../framework/provider/layout/layout_controller.dart';
import '../../framework/logs/talker.dart';
import '../AppScaffold.dart';

class UpdatePage extends ConsumerStatefulWidget {
  final AppUpdateInfo updateInfo;

  const UpdatePage({super.key, required this.updateInfo});

  @override
  ConsumerState<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends ConsumerState<UpdatePage> with WindowListener {
  double _progress = 0;
  bool _isDownloading = false;
  bool _hasStarted = false;
  String? _error;

  bool get _isForceUpdate => widget.updateInfo.forceUpdate;

  @override
  void initState() {
    super.initState();
    if (DeviceUtil.isRealDesktop()) {
      windowManager.addListener(this);
    }
  }

  @override
  void onWindowMaximize() {
    ref.read(layoutControllerProvider.notifier).toggleExtended();
  }

  @override
  void onWindowUnmaximize() {
    ref.read(layoutControllerProvider.notifier).toggleExtended();
  }

  @override
  void dispose() {
    if (DeviceUtil.isRealDesktop()) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _hasStarted = true;
      _error = null;
    });

    try {
      final tempDir = await getApplicationDocumentsDirectory();
      final fileName = widget.updateInfo.downloadUrl.split('/').last;
      final savePath = "${tempDir.path}/$fileName";

      log.info("🚀 准备下载更新文件至: $savePath");

      final response = await DioClient().download(
        widget.updateInfo.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      if (response.statusCode != 200) {
        throw Exception("服务器响应异常: ${response.statusCode}");
      }

      log.info("📦 下载完成，正在唤起安装程序...");

      final result = await OpenFile.open(savePath);

      if (result.type == ResultType.done) {
        log.info("✅ 安装程序已启动，执行安全退出序列...");

        if (DeviceUtil.isRealDesktop()) {
          await windowManager.hide();
          windowManager.removeListener(this);
        }

        await Future.delayed(const Duration(milliseconds: 500));
        exit(0);
      } else {
        throw Exception("无法启动安装包: ${result.message}");
      }
    } catch (e) {
      log.error("❌ 更新失败: $e");
      setState(() {
        _isDownloading = false;
        _error = _formatError(e);
      });
    }
  }

  String _formatError(dynamic e) {
    String s = e.toString();
    if (s.contains("404")) return "update_error_404".tr();
    if (s.contains("SocketException")) return "update_error_network".tr();
    return "update_error_generic".tr(args: [e.toString()]);
  }

  String _downloadText() {
    if (_progress >= 1) {
      return 'update_preparing_install'.tr();
    }
    return '${(_progress * 100).toInt()}% · ${'update_downloading'.tr()}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 560;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ref.watch(appThemeProvider),
      home: AppScaffold(
        body: PopScope(
          canPop: !_isForceUpdate,
          child: SafeArea(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isCompact ? width - 24 : 560,
                ),
                padding: EdgeInsets.all(isCompact ? 16 : 24),
                margin: EdgeInsets.all(isCompact ? 12 : 20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: colorScheme.primary.withValues(alpha: .12),
                            ),
                            child: Icon(
                              Icons.system_update_alt_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'update_new_version'.tr(),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'v${widget.updateInfo.latestVersion}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isForceUpdate)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'FORCE',
                                style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'update_release_notes'.tr(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 220),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withValues(
                            alpha: 0.26,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            widget.updateInfo.releaseNotes.isEmpty
                                ? 'update_default_notes'.tr()
                                : widget.updateInfo.releaseNotes,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_isDownloading) ...[
                        LinearProgressIndicator(
                          value: _progress <= 0 ? null : _progress,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _downloadText(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _startDownload,
                            icon: const Icon(Icons.download_rounded),
                            label: Text(
                              _hasStarted
                                  ? 'update_retry_download'.tr()
                                  : 'update_now'.tr(),
                            ),
                          ),
                        ),
                      ],
                      if (_error != null && !_isDownloading) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.onErrorContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: colorScheme.onErrorContainer,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

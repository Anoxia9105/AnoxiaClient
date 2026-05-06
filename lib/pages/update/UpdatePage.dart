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

  List<String> _releaseNoteLines() {
    final raw = widget.updateInfo.releaseNotes.trim();
    final source = raw.isEmpty ? 'update_default_notes'.tr() : raw;
    return source
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 560;
    final notes = _releaseNoteLines();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ref.watch(appThemeProvider),
      home: AppScaffold(
        body: PopScope(
          canPop: !_isForceUpdate,
          child: SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withValues(alpha: .10),
                    colorScheme.surface,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isCompact ? width - 24 : 620,
                  ),
                  margin: EdgeInsets.all(isCompact ? 12 : 20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: .96),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .08),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isCompact ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary.withValues(alpha: .18),
                                colorScheme.primary.withValues(alpha: .06),
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: colorScheme.primary.withValues(
                                    alpha: .18,
                                  ),
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
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
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'v${widget.updateInfo.latestVersion}',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isForceUpdate)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: colorScheme.errorContainer,
                                  ),
                                  child: Text(
                                    'FORCE',
                                    style: TextStyle(
                                      color: colorScheme.onErrorContainer,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: .3,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'update_release_notes'.tr(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 240),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withValues(
                              alpha: .24,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: notes
                                  .map(
                                    (line) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                            ),
                                            child: Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              line,
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_isDownloading) ...[
                          LinearProgressIndicator(
                            value: _progress <= 0 ? null : _progress,
                            minHeight: 9,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                _progress >= 1
                                    ? Icons.inventory_2_outlined
                                    : Icons.downloading_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _downloadText(),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
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
                              borderRadius: BorderRadius.circular(10),
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
      ),
    );
  }
}

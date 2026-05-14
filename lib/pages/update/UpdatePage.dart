import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
      if (DeviceUtil.isRealMobile()) {
        final uri = Uri.tryParse(widget.updateInfo.downloadUrl);
        if (uri == null) {
          throw Exception('invalid update url');
        }

        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          throw Exception('cannot open update url');
        }

        if (!mounted) return;
        setState(() {
          _isDownloading = false;
          _progress = 0;
        });
        return;
      }

      final tempDir = await getApplicationDocumentsDirectory();
      final fileName = widget.updateInfo.downloadUrl.split('/').last;
      final savePath = "${tempDir.path}/$fileName";

      log.info("🚀 准备下载更新文件至: $savePath");

      final response = await DioClient().download(
        widget.updateInfo.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            if (!mounted) return;
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

      final result = await OpenFilex.open(savePath);

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
      if (!mounted) return;
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
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 560;
    final notes = _releaseNoteLines();
    // 从其他页面 push 进来时，Navigator 有上一层，显示返回按钮
    final canGoBack = Navigator.canPop(context) && !_isForceUpdate;

    return AppScaffold(
      body: PopScope(
        canPop: !_isForceUpdate,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 16 : 24,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isCompact ? double.infinity : 560,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 返回按钮（从设置页跳转时显示）──
                    if (canGoBack) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Text('back'.tr()),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // ── Header ──
                    _buildHeader(context, theme, colorScheme),

                    const SizedBox(height: 20),

                    // ── Release Notes ──
                    _buildReleaseNotes(
                      context,
                      theme,
                      colorScheme,
                      isDark,
                      notes,
                    ),

                    const SizedBox(height: 20),

                    // ── Action Area ──
                    _buildActionArea(theme, colorScheme, isDark),

                    // ── Error ──
                    if (_error != null && !_isDownloading) ...[
                      const SizedBox(height: 12),
                      _buildError(colorScheme),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: .50),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: .06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.system_update_alt_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'update_new_version'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: colorScheme.primaryContainer,
                      ),
                      child: Text(
                        'v${widget.updateInfo.latestVersion}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isForceUpdate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: colorScheme.errorContainer,
              ),
              child: Text(
                'FORCE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReleaseNotes(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    List<String> notes,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: .50),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: .06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.article_outlined,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'update_release_notes'.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: colorScheme.secondaryContainer,
                ),
                child: Text(
                  '${notes.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: notes.map((line) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(line, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    if (!_isDownloading) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: _startDownload,
          icon: const Icon(Icons.download_rounded),
          label: Text(
            _hasStarted ? 'update_retry_download'.tr() : 'update_now'.tr(),
          ),
        ),
      );
    }

    // Downloading state
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: .50),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: .06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                child: Text(_downloadText(), style: theme.textTheme.bodyMedium),
              ),
              Text(
                '${(_progress * 100).clamp(0, 100).toInt()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _progress <= 0 ? null : _progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.error.withValues(alpha: .30)),
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
    );
  }
}

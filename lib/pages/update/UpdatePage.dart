import 'dart:io';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
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
    if (s.contains("404")) return "远程更新文件不存在 (404)";
    if (s.contains("SocketException")) return "网络连接失败，请检查联网状态";
    return "下载过程出错: $e";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ref.watch(appThemeProvider),
      home: AppScaffold(
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  "发现新版本",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // 版本号
                Text(
                  "v${widget.updateInfo.latestVersion}",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                // 更新说明
                Text(
                  "更新说明",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.updateInfo.releaseNotes.isEmpty
                          ? "性能优化与稳定性提升"
                          : widget.updateInfo.releaseNotes,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 下载进度或按钮
                if (_isDownloading) ...[
                  LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${(_progress * 100).toInt()}% - ${_progress >= 1 ? '准备安装...' : '下载中...'}",
                    style: theme.textTheme.bodyMedium,
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _startDownload,
                      child: Text(_hasStarted ? "重试下载" : "立即升级"),
                    ),
                  ),
                ],

                // 错误信息
                if (_error != null && !_isDownloading) ...[
                  const SizedBox(height: 16),
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
    );
  }
}

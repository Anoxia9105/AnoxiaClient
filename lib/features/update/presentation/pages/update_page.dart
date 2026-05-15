import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../common/utils/DeviceUtil.dart';
import '../../../../framework/logs/talker.dart';
import '../../../../framework/network/DioClient.dart';
import '../../../../framework/provider/core/AppUpdateInfo.dart';
import '../../../../framework/provider/layout/layout_controller.dart';
import '../../../../common/widgets/app/app_scaffold.dart';
import '../widgets/update_sections.dart';

/// 应用更新页面
///
/// 显示应用更新信息、下载进度，并支持更新安装
class UpdatePage extends ConsumerStatefulWidget {
  /// 更新信息对象
  final AppUpdateInfo updateInfo;

  const UpdatePage({super.key, required this.updateInfo});

  @override
  ConsumerState<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends ConsumerState<UpdatePage> with WindowListener {
  /// 下载进度（0-1）
  double _progress = 0;
  /// 是否正在下载
  bool _isDownloading = false;
  /// 是否已经开始下载
  bool _hasStarted = false;
  /// 错误信息
  String? _error;

  /// 是否为强制更新
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
      final savePath = '${tempDir.path}/$fileName';

      log.info('🚀 准备下载更新文件至: $savePath');

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
        throw Exception('服务器响应异常: ${response.statusCode}');
      }

      log.info('📦 下载完成，正在唤起安装程序...');

      final result = await OpenFilex.open(savePath);

      if (result.type == ResultType.done) {
        log.info('✅ 安装程序已启动，执行安全退出序列...');

        if (DeviceUtil.isRealDesktop()) {
          await windowManager.hide();
          windowManager.removeListener(this);
        }

        await Future.delayed(const Duration(milliseconds: 500));
        exit(0);
      } else {
        throw Exception('无法启动安装包: ${result.message}');
      }
    } catch (e) {
      log.error('❌ 更新失败: $e');
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
    return 'update_error_generic'.tr(args: [e.toString()]);
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
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 560;
    final notes = _releaseNoteLines();
    final canGoBack = context.canPop() && !_isForceUpdate;

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
                    if (canGoBack) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Text('back'.tr()),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    UpdateHeaderCard(
                      latestVersion: widget.updateInfo.latestVersion,
                      isForceUpdate: _isForceUpdate,
                    ),
                    const SizedBox(height: 20),
                    UpdateReleaseNotesCard(notes: notes),
                    const SizedBox(height: 20),
                    UpdateActionArea(
                      isDownloading: _isDownloading,
                      hasStarted: _hasStarted,
                      progress: _progress,
                      onStartDownload: _startDownload,
                    ),
                    if (_error != null && !_isDownloading) ...[
                      const SizedBox(height: 12),
                      UpdateErrorCard(message: _error!),
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
}

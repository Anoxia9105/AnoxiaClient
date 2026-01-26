import 'dart:io';

import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/provider/core/AppUpdateInfo.dart';
import 'package:anoxia/pages/AppScaffold.dart';
import 'package:flutter/material.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../framework/logs/talker.dart';

class UpdatePage extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const UpdatePage({super.key, required this.updateInfo});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  double _progress = 0;
  bool _isDownloading = false;
  bool _hasStarted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
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

      log.info("Downloading update to $savePath");

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
        throw Exception("服务器返回错误: ${response.statusCode}");
      }

      log.info("Download completed. Opening file...");
      final result = await OpenFile.open(savePath);
      log.info("Open file result: ${result.type} ${result.message}");

      if (result.type == ResultType.done) {
        log.info("✅ 安装程序已启动，正在关闭当前应用...");

        // 给系统一点点时间反应，然后退出
        await Future.delayed(const Duration(milliseconds: 1000));
        exit(0); // 彻底退出进程
      } else if (result.type != ResultType.noAppToOpen) {
        throw Exception("无法打开安装程序: ${result.message}");
      }
    } catch (e) {
      log.error("Download failed: $e");
      setState(() {
        _isDownloading = false;
        _error = _formatError(e);
      });
    }
  }

  String _formatError(dynamic e) {
    String errorStr = e.toString();
    if (errorStr.contains("404")) {
      return "更新文件不存在 (404)，请联系管理员。";
    } else if (errorStr.contains("SocketException")) {
      return "网络连接失败，请检查网络设置。";
    } else if (errorStr.contains("Timeout")) {
      return "连接超时，请重试。";
    }
    return "下载失败: $e";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                "发现新版本 v${widget.updateInfo.latestVersion}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.updateInfo.releaseNotes,
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 32),
              if (_isDownloading) ...[
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 16),
                Text("正在下载: ${(_progress * 100).toStringAsFixed(1)}%"),
              ] else ...[
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startDownload,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_hasStarted ? "立即重试" : "开始更新"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

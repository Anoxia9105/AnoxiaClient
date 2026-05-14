import 'dart:io';

import 'package:anoxia/common/utils/fileUtil.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import '../../../../../framework/protocol/message/Attachment.dart';
import 'base/message_render_strategy.dart';

class FileMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final fileList = message.attachments;

    if (fileList.isEmpty) {
      return const SizedBox.shrink();
    }

    return _FileMessageList(fileList: fileList);
  }
}

class _FileMessageList extends StatefulWidget {
  final List<Attachment> fileList;

  const _FileMessageList({required this.fileList});

  @override
  State<_FileMessageList> createState() => _FileMessageListState();
}

class _FileMessageListState extends State<_FileMessageList> {
  final Map<String, double> _progressMap = {};
  final Map<String, bool> _downloadingMap = {};
  final Map<String, String> _downloadedPathMap = {};

  String _fileKey(Attachment file) {
    return file.id ?? file.url ?? file.name ?? file.hashCode.toString();
  }

  Future<Directory> _resolveDownloadDirectory() async {
    final downloadDir = await getDownloadsDirectory();
    if (downloadDir != null) {
      return downloadDir;
    }
    return getApplicationDocumentsDirectory();
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    if (!normalized.contains('/')) return normalized;
    return normalized.split('/').last;
  }

  String _extension(String fileName) {
    final idx = fileName.lastIndexOf('.');
    if (idx <= 0 || idx == fileName.length - 1) return '';
    return fileName.substring(idx + 1);
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  String _buildFileName(Attachment file) {
    final urlName = _basename((file.url ?? '').split('?').first);
    final candidateName = _sanitizeFileName(file.name ?? '');

    String fileName;
    if (candidateName.isEmpty) {
      fileName = urlName.isNotEmpty
          ? _sanitizeFileName(urlName)
          : 'download_${DateTime.now().millisecondsSinceEpoch}';
    } else {
      fileName = candidateName;
    }

    // 确保后缀不丢失：优先用自身后缀，其次从 URL 补，最后从 file.type 兜底
    final currentExt = _extension(fileName);
    if (currentExt.isEmpty) {
      final urlExt = _extension(urlName);
      final typeExt = (file.type ?? '').toLowerCase().trim();
      final fallbackExt = urlExt.isNotEmpty ? urlExt : typeExt;
      if (fallbackExt.isNotEmpty) {
        fileName = '$fileName.$fallbackExt';
      }
    }

    return fileName;
  }

  /// 如果同名文件已存在，自动加编号避免覆盖，如 file(1).pdf
  String _uniqueSavePath(String basePath) {
    var file = File(basePath);
    if (!file.existsSync()) return basePath;

    final dir = file.parent.path;
    final name = _basename(basePath);
    final dotIdx = name.lastIndexOf('.');
    final nameWithoutExt = dotIdx > 0 ? name.substring(0, dotIdx) : name;
    final ext = dotIdx > 0 ? name.substring(dotIdx) : '';

    var index = 1;
    while (file.existsSync()) {
      file = File('$dir${Platform.pathSeparator}$nameWithoutExt($index)$ext');
      index++;
    }
    return file.path;
  }

  /// 在下载目录中查找该附件对应的已有文件（支持带编号的重名文件）
  Future<String?> _findExistingFile(Attachment file) async {
    final downloadDir = await _resolveDownloadDirectory();
    final fileName = _buildFileName(file);
    final directPath = '${downloadDir.path}${Platform.pathSeparator}$fileName';

    // 精确匹配
    if (File(directPath).existsSync()) return directPath;

    // 查找带编号的版本，如 file(1).pdf, file(2).pdf
    final dotIdx = fileName.lastIndexOf('.');
    final nameWithoutExt = dotIdx > 0
        ? fileName.substring(0, dotIdx)
        : fileName;
    final ext = dotIdx > 0 ? fileName.substring(dotIdx) : '';

    for (var i = 1; i <= 50; i++) {
      final numberedPath =
          '${downloadDir.path}${Platform.pathSeparator}$nameWithoutExt($i)$ext';
      if (!File(numberedPath).existsSync()) break;
      // 存在则返回最新的编号文件（继续找更大编号）
      if (!File(
        '${downloadDir.path}${Platform.pathSeparator}$nameWithoutExt(${i + 1})$ext',
      ).existsSync()) {
        return numberedPath;
      }
    }

    return null;
  }

  Future<void> _openFileLocation(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      Toast.showToast('file_not_found'.tr());
      return;
    }

    if (Platform.isWindows) {
      final normalized = file.path.replaceAll('/', '\\');
      // explorer /select, 无论成功与否 exitCode 都可能非0，直接 return
      await Process.run('explorer', ['/select,', normalized]);
      return;
    }

    if (Platform.isMacOS) {
      await Process.run('open', ['-R', file.path]);
      return;
    }

    if (Platform.isLinux) {
      await Process.run('xdg-open', [file.parent.path]);
      return;
    }

    final openResult = await OpenFilex.open(file.parent.path);
    if (openResult.type != ResultType.done) {
      Toast.showToast('file_open_dir_failed'.tr(args: [openResult.message]));
    }
  }

  Future<void> _handleFileTap(BuildContext context, Attachment file) async {
    final key = _fileKey(file);

    if (_downloadingMap[key] == true) {
      return;
    }

    // 每次点击先去磁盘检查文件是否已存在（不依赖内存状态）
    final existingPath = await _findExistingFile(file);
    if (existingPath != null) {
      // 同步内存状态
      if (_downloadedPathMap[key] != existingPath) {
        setState(() {
          _downloadedPathMap[key] = existingPath;
          _progressMap.remove(key);
        });
      }
      await _openFileLocation(existingPath);
      return;
    }

    // 磁盘上不存在 → 清除可能残留的内存状态
    if (_downloadedPathMap.containsKey(key)) {
      setState(() {
        _downloadedPathMap.remove(key);
        _progressMap.remove(key);
      });
    }

    if ((file.url ?? '').isEmpty) {
      Toast.showToast('file_url_invalid'.tr());
      return;
    }

    setState(() {
      _downloadingMap[key] = true;
      _progressMap[key] = 0;
    });

    try {
      final downloadDir = await _resolveDownloadDirectory();
      final fileName = _buildFileName(file);
      final savePath = _uniqueSavePath(
        '${downloadDir.path}${Platform.pathSeparator}$fileName',
      );

      final response = await DioClient().download(
        file.url!,
        savePath,
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          if (total > 0) {
            setState(() {
              _progressMap[key] = received / total;
            });
          }
        },
      );

      if (response.statusCode != 200) {
        throw Exception('下载失败: ${response.statusCode}');
      }

      if (!mounted) return;
      setState(() {
        _progressMap[key] = 1;
        _downloadedPathMap[key] = savePath;
      });

      Toast.showToast('file_download_complete'.tr(args: [fileName]));
    } catch (e) {
      Toast.showToast('file_download_failed'.tr(args: [e.toString()]));
      if (!mounted) return;
      setState(() {
        _progressMap.remove(key);
      });
    } finally {
      if (mounted) {
        setState(() {
          _downloadingMap[key] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.fileList.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;
          final key = _fileKey(file);
          final progress = _progressMap[key];
          final isDownloading = _downloadingMap[key] == true;
          final isDownloaded = _downloadedPathMap.containsKey(key);
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 8.0), // 文件之间的间距
            child: _buildFileItem(
              context,
              file,
              progress: progress,
              isDownloading: isDownloading,
              isDownloaded: isDownloaded,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    Attachment file, {
    required double? progress,
    required bool isDownloading,
    required bool isDownloaded,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleFileTap(context, file),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 文件图标
              FileUtil.buildFileIcon(file.type ?? ''),
              const SizedBox(width: 10),

              // 文件信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      file.name ?? 'file_unknown'.tr(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // 文件大小 + 状态行
                    Row(
                      children: [
                        Text(
                          FileUtil.formatFileSize(file.size ?? 0),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        if (isDownloaded) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.4,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'file_downloaded_open_location'.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // 下载进度条
                    if (isDownloading) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'file_downloading'.tr(
                          args: [((progress ?? 0) * 100).toInt().toString()],
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 右侧操作按钮
              _buildTrailingIcon(
                context,
                isDownloading,
                isDownloaded,
                progress,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingIcon(
    BuildContext context,
    bool isDownloading,
    bool isDownloaded,
    double? progress,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isDownloading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: progress,
          color: colorScheme.primary,
        ),
      );
    }

    if (isDownloaded) {
      return Icon(
        Icons.folder_open_rounded,
        size: 18,
        color: colorScheme.primary.withValues(alpha: 0.8),
      );
    }

    return Icon(
      Icons.download_rounded,
      size: 18,
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    );
  }
}

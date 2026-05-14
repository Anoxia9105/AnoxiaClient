import 'dart:io';

import 'package:anoxia/common/utils/StringUtil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 文件工具类
///
/// 提供文件选择、路径处理和目录管理等常用操作。
class FileUtil {
  FileUtil._();

  /// 选择单个文件
  ///
  /// [type] 文件类型过滤
  /// [allowMultiple] 是否允许多选
  static Future<PlatformFile?> pickFile({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    final result = await FilePicker.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      allowMultiple: allowMultiple,
    );

    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  /// 选择多个文件
  static Future<List<PlatformFile>> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return [];
    return result.files;
  }

  /// 获取文件扩展名
  ///
  /// 包含点号，如 ".jpg"
  static String getExtension(String path) {
    return p.extension(path).toLowerCase();
  }

  /// 获取不带扩展名的文件名
  static String getBaseName(String path) {
    return p.basenameWithoutExtension(path);
  }

  /// 获取完整文件名（带扩展名）
  static String getFileName(String path) {
    return p.basename(path);
  }

  /// 获取文件大小描述
  static String getFileSizeDescription(int bytes) {
    return StringUtil.formatFileSize(bytes);
  }

  /// 格式化文件大小（兼容旧调用）
  static String formatFileSize(int bytes) {
    return getFileSizeDescription(bytes);
  }

  /// 构建文件类型图标
  static Widget buildFileIcon(String fileType) {
    final ext = fileType.trim().toLowerCase().replaceFirst('.', '');

    IconData icon;
    Color color;

    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp']
        .contains(ext)) {
      icon = Icons.image_rounded;
      color = Colors.blueAccent;
    } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
      icon = Icons.movie_rounded;
      color = Colors.deepPurpleAccent;
    } else if (['mp3', 'wav', 'aac', 'flac', 'ogg'].contains(ext)) {
      icon = Icons.audiotrack_rounded;
      color = Colors.green;
    } else if (['pdf'].contains(ext)) {
      icon = Icons.picture_as_pdf_rounded;
      color = Colors.redAccent;
    } else if (['doc', 'docx'].contains(ext)) {
      icon = Icons.description_rounded;
      color = Colors.indigo;
    } else if (['xls', 'xlsx', 'csv'].contains(ext)) {
      icon = Icons.table_chart_rounded;
      color = Colors.teal;
    } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      icon = Icons.folder_zip_rounded;
      color = Colors.orange;
    } else if (ext == 'error') {
      icon = Icons.error_outline_rounded;
      color = Colors.redAccent;
    } else {
      icon = Icons.insert_drive_file_rounded;
      color = Colors.blueGrey;
    }

    return Icon(icon, size: 24, color: color);
  }

  /// 判断是否为图片文件
  static bool isImageFile(String path) {
    final ext = getExtension(path);
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.bmp']
        .contains(ext);
  }

  /// 获取应用临时目录
  static Future<String> getTempDirectory() async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }

  /// 获取应用文档目录
  static Future<String> getDocumentsDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// 在临时目录创建临时文件
  static Future<File> createTempFile(List<int> bytes, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    return file.writeAsBytes(bytes);
  }

  /// 清理临时目录
  static Future<void> clearTempDirectory() async {
    if (kIsWeb) return;
    try {
      final dir = await getTemporaryDirectory();
      final files = dir.listSync();
      for (final entity in files) {
        if (entity is File) {
          await entity.delete();
        }
      }
    } catch (_) {}
  }

  /// 保存文件到下载目录（仅 Windows/macOS）
  static Future<String?> saveToDownloads(
      List<int> bytes,
      String fileName,
      ) async {
    if (kIsWeb) return null;

    try {
      Directory? dir;
      if (Platform.isWindows) {
        dir = Directory(Platform.environment['USERPROFILE']! + '\\Downloads');
      } else if (Platform.isMacOS) {
        dir = Directory(Platform.environment['HOME']! + '/Downloads');
      }

      if (dir == null || !await dir.exists()) return null;

      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}

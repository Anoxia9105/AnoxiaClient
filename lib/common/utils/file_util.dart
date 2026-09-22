import 'dart:io';
import 'dart:convert';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/common/utils/string_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
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
      // Web/Wasm 下 path 为 null，bytes 只有 withData:true 才有。
      withData: true,
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
      withData: true,
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
  static Widget buildFileIcon(String fileType, {String? fileName}) {
    var ext = fileType.trim().toLowerCase().replaceFirst('.', '');
    if (ext.contains('/')) {
      ext = ext.split('/').last;
    }
    final nameExtension = fileName == null
        ? ''
        : p.extension(fileName).toLowerCase().replaceFirst('.', '');
    if (nameExtension.isNotEmpty) ext = nameExtension;

    List<List<dynamic>> icon;
    Color color;

    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp']
        .contains(ext)) {
      icon = HugeIcons.strokeRoundedImage01;
      color = Colors.blueAccent;
    } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
      icon = HugeIcons.strokeRoundedFilmRoll01;
      color = Colors.deepPurpleAccent;
    } else if (['mp3', 'wav', 'aac', 'flac', 'ogg'].contains(ext)) {
      icon = HugeIcons.strokeRoundedMusicNote01;
      color = Colors.green;
    } else if (['pdf'].contains(ext)) {
      icon = HugeIcons.strokeRoundedPdf01;
      color = Colors.redAccent;
    } else if (['doc', 'docx', 'odt', 'rtf', 'txt', 'md'].contains(ext)) {
      icon = HugeIcons.strokeRoundedFile01;
      color = Colors.indigo;
    } else if (['xls', 'xlsx', 'csv', 'ods'].contains(ext)) {
      icon = HugeIcons.strokeRoundedTable01;
      color = Colors.teal;
    } else if (['ppt', 'pptx', 'odp'].contains(ext)) {
      icon = HugeIcons.strokeRoundedPresentation01;
      color = Colors.deepOrange;
    } else if ([
      'dart',
      'js',
      'ts',
      'jsx',
      'tsx',
      'java',
      'kt',
      'swift',
      'py',
      'go',
      'rs',
      'c',
      'cpp',
      'h',
      'html',
      'css',
      'json',
      'xml',
      'yaml',
      'yml',
    ].contains(ext)) {
      icon = HugeIcons.strokeRoundedCode;
      color = Colors.cyan.shade700;
    } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      icon = HugeIcons.strokeRoundedFolderZip;
      color = Colors.orange;
    } else if (ext == 'error') {
      icon = HugeIcons.strokeRoundedAlertCircle;
      color = Colors.redAccent;
    } else {
      icon = HugeIcons.strokeRoundedFile02;
      color = Colors.blueGrey;
    }

    return HugeIcon(icon: icon, size: 24, color: color);
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

  /// 保存背景图到本地存储
  ///
  /// 原生端：保存图片文件到文档目录，返回文件路径。
  /// Web 端：将图片压缩后转 base64 存入，返回 `data:image/jpeg;base64,...` URI。
  static Future<String?> saveBackgroundImage(Uint8List bytes) async {
    final compressed = compressImage(bytes);
    if (kIsWeb) {
      final base64Str = base64Encode(compressed);
      return 'data:image/jpeg;base64,$base64Str';
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final bgDir = Directory('${dir.path}${Platform.pathSeparator}bg');
      if (!await bgDir.exists()) {
        await bgDir.create(recursive: true);
      }
      final file = File(
          '${bgDir.path}${Platform.pathSeparator}background.jpg');
      await file.writeAsBytes(compressed);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// 删除原生端背景图文件（Web 端无需操作）
  static Future<void> deleteBackgroundImageFile(String path) async {
    if (kIsWeb) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// 压缩图片到合理尺寸（最长边 1920px，JPEG quality 70）
  static Uint8List compressImage(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    const maxDim = 1920;
    var result = decoded;
    if (decoded.width > maxDim || decoded.height > maxDim) {
      if (decoded.width >= decoded.height) {
        result = img.copyResize(decoded, width: maxDim);
      } else {
        result = img.copyResize(decoded, height: maxDim);
      }
    }
    return Uint8List.fromList(img.encodeJpg(result, quality: 70));
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
        dir = Directory('${Platform.environment['USERPROFILE']!}\\Downloads');
      } else if (Platform.isMacOS) {
        dir = Directory('${Platform.environment['HOME']!}/Downloads');
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

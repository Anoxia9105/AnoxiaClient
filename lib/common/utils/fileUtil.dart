import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;

class FileUtil {

  /// 写入文件到临时目录
  static Future<File> writeToTempFile(Uint8List bytes, String ext) async {
    final dir = await getTemporaryDirectory();
    print("写入临时文件：${dir.path}");
    final file = File(
      p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.$ext'),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// 格式化文件大小
  ///
  ///参数:
  ///- [bytes] 字节数
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return "${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
  }

  /// 根据文件类型 返回文件图标
  ///
  ///参数:
  ///- [] xxx
  static Widget buildFileIcon(String ext) {
    IconData iconData;
    Color color;

    switch (ext.toLowerCase()) {
      case 'error':
        iconData = Icons.error_outline;
        color = Colors.redAccent;
        break;
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        color = Colors.redAccent;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description;
        color = Colors.blue;
        break;
      case 'zip':
      case 'rar':
        iconData = Icons.folder_zip;
        color = Colors.orange;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: color, size: 28),
    );
  }
}

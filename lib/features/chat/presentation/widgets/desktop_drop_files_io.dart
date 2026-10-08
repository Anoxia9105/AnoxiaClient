import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

/// 只读取文件元数据，上传和预览仍走原有路径，避免大文件占满内存。
Future<({List<PlatformFile> files, List<String> rejected})>
prepareDesktopDropFiles(List<XFile> items) async {
  final files = <PlatformFile>[];
  final rejected = <String>[];
  final paths = <String>{};
  for (final item in items) {
    final path = p.normalize(item.path);
    final name = p.basename(path);
    if (!paths.add(path)) continue;
    try {
      final stat = await File(item.path).stat();
      if (stat.type != FileSystemEntityType.file) {
        rejected.add(name);
        continue;
      }
      // stat 成功不代表可读；仅打开并关闭文件，不预读全部内容。
      final handle = await File(item.path).open();
      await handle.close();
      files.add(PlatformFile(name: name, path: item.path, size: stat.size));
    } on FileSystemException {
      rejected.add(name);
    }
  }
  return (files: files, rejected: rejected);
}

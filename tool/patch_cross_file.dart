import 'dart:io';

/// 修复 cross_file 0.3.5+4 在 dart:io 平台下 XFile.fromData 丢弃 name 的问题
///
/// 背景：
/// - cross_file 的 `lib/src/types/io.dart` 中 `XFile.fromData` 的构造函数
///   注释即写明 `[name] is ignored`，且 `get name` 仅从 `File.path` 截取 basename。
/// - Anoxia 的聊天图片/文件上传在桌面端（Windows/macOS/Linux）会通过
///   `XFile.fromData(bytes, name: originalName)` 构造对象（例如头像、背景、便签图片等），
///   在未修复前 `file.name` 恒为 ''，导致 `DioClient.uploadFile` 以空文件名发往
///   `POST /file/uploadV2`，被服务端 `ChatUploadPolicy.isAllowedFile("", size)` 判定为
///   `INVALID_FILE`（`fileName.isBlank()`），表现为“聊天输入框图片/文件上传失败”。
/// - 浏览器端（Web/Wasm）的 `XFile` 实现正确保存 `name`，不受影响。
///
/// 修复内容（对 pub cache 中的 `cross_file-0.3.5+4/lib/src/types/io.dart`）：
/// 1. `XFile(String path, {name})` 与 `XFile.fromData` 均新增 `_name` 字段持久化传入的 `name`；
/// 2. `get name` 优先返回 `_name`（非空时），否则回落到 `File.path` 的 basename；
/// 3. `XFile.fromData` 的 `_length` 初始化改为 `length ?? bytes.length`（与 Web 端一致）。
///
/// 用法：
///   flutter pub get
///   dart run tool/patch_cross_file.dart
///
/// 该脚本幂等，可重复执行；若已修复则跳过。
void main() {
  final pubCache = Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['APPDATA'] ?? ''}\\Pub\\Cache';
  // 优先从 package_config.json 解析 cross_file 实际路径，避免硬编码版本号
  final packageConfig = File('.dart_tool/package_config.json');
  String? crossFileRoot;
  if (packageConfig.existsSync()) {
    final content = packageConfig.readAsStringSync();
    final match = RegExp(r'"name"\s*:\s*"cross_file"[^}]*"rootUri"\s*:\s*"([^"]+)"')
        .firstMatch(content);
    if (match != null) {
      var uri = match.group(1)!;
      // file:///C:/.../cross_file-0.3.5+4
      if (uri.startsWith('file:///')) {
        uri = Uri.decodeFull(uri.substring(8));
      }
      crossFileRoot = uri;
    }
  }
  // 回退：扫描 pub cache
  if (crossFileRoot == null) {
    final candidates = [
      '$pubCache/hosted/pub.flutter-io.cn',
      '$pubCache/hosted/pub.dev',
      '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev',
    ];
    for (final base in candidates) {
      final dir = Directory(base);
      if (!dir.existsSync()) continue;
      final entries = dir.listSync().whereType<Directory>().where(
          (d) => d.path.contains('cross_file-'));
      if (entries.isNotEmpty) {
        // 取最新版本
        final sorted = entries.toList()
          ..sort((a, b) => b.path.compareTo(a.path));
        crossFileRoot = sorted.first.path;
        break;
      }
    }
  }

  if (crossFileRoot == null) {
    stderr.writeln('[patch_cross_file] 未找到 cross_file 包，请先执行 flutter pub get');
    exit(1);
  }

  final ioFile = File('$crossFileRoot/lib/src/types/io.dart');
  if (!ioFile.existsSync()) {
    stderr.writeln('[patch_cross_file] 未找到 ${ioFile.path}');
    exit(1);
  }

  final original = ioFile.readAsStringSync();
  // 已修复则跳过
  if (original.contains('final String? _name;') &&
      // ignore: prefer_single_quotes
      original.contains("if (_name != null && _name!.isNotEmpty) return _name!;")) {
    stdout.writeln('[patch_cross_file] 已是修复后版本，跳过：${ioFile.path}');
    return;
  }

  final fixed = _buildFixedContent();
  // 备份
  final backup = File('${ioFile.path}.bak');
  if (!backup.existsSync()) {
    ioFile.copySync(backup.path);
    stdout.writeln('[patch_cross_file] 已备份至 ${backup.path}');
  }
  ioFile.writeAsStringSync(fixed);
  stdout.writeln('[patch_cross_file] 修复完成：${ioFile.path}');
  stdout.writeln('[patch_cross_file] 关键修复：XFile.fromData 在 IO 端正确保留 name，DioClient 空文件名兜底为 "file" 参见 lib/framework/network/dio_client.dart:236');
}

String _buildFixedContent() {
  return r'''// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import './base.dart';

// ignore_for_file: avoid_unused_constructor_parameters

/// A CrossFile backed by a dart:io File.
class XFile extends XFileBase {
  /// Construct a CrossFile object backed by a dart:io File.
  ///
  /// [bytes] is ignored; the parameter exists only to match the web version of
  /// the constructor. To construct a dart:io XFile from bytes, use
  /// [XFile.fromData].
  ///
  /// [mimeType] is not inferred from [path]. The [mimeType] property returns the
  /// value explicitly provided here, if any.
  ///
  // ignore: use_super_parameters
  XFile(
    String path, {
    String? mimeType,
    String? name,
    int? length,
    Uint8List? bytes,
    DateTime? lastModified,
  }) : _mimeType = mimeType,
        _file = File(path),
        _bytes = null,
        _lastModified = lastModified,
        _name = name,
        _length = length,
        super(path);

  /// Construct an CrossFile from its data
  ///
  /// The [mimeType] property returns the value explicitly provided here, if any.
  XFile.fromData(
    Uint8List bytes, {
    String? mimeType,
    String? path,
    String? name,
    int? length,
    DateTime? lastModified,
  }) : _mimeType = mimeType,
        _bytes = bytes,
        _file = File(path ?? ''),
        _length = length ?? bytes.length,
        _lastModified = lastModified,
        _name = name,
        super(path);

  final File _file;
  final String? _mimeType;
  final DateTime? _lastModified;
  final String? _name;
  int? _length;

  final Uint8List? _bytes;

  @override
  Future<DateTime> lastModified() {
    if (_lastModified != null) {
      return Future<DateTime>.value(_lastModified);
    }
    // ignore: avoid_slow_async_io
    return _file.lastModified();
  }

  @override
  Future<void> saveTo(String path) async {
    if (_bytes == null) {
      await _file.copy(path);
    } else {
      final fileToSave = File(path);
      // TODO(kevmoo): Remove ignore and fix when the MIN Dart SDK is 3.3
      // ignore: unnecessary_non_null_assertion
      await fileToSave.writeAsBytes(_bytes!);
    }
  }

  @override
  String? get mimeType => _mimeType;

  @override
  String get path => _file.path;

  @override
  String get name {
    if (_name != null && _name!.isNotEmpty) return _name!;
    if (_file.path.isEmpty) return '';
    return _file.path.split(Platform.pathSeparator).last;
  }

  @override
  Future<int> length() {
    if (_length != null) {
      return Future<int>.value(_length);
    }
    return _file.length();
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) {
    if (_bytes != null) {
      // TODO(kevmoo): Remove ignore and fix when the MIN Dart SDK is 3.3
      // ignore: unnecessary_non_null_assertion
      return Future<String>.value(String.fromCharCodes(_bytes!));
    }
    return _file.readAsString(encoding: encoding);
  }

  @override
  Future<Uint8List> readAsBytes() {
    if (_bytes != null) {
      return Future<Uint8List>.value(_bytes);
    }
    return _file.readAsBytes();
  }

  Stream<Uint8List> _getBytes(int? start, int? end) async* {
    final Uint8List bytes = _bytes!;
    yield bytes.sublist(start ?? 0, end ?? bytes.length);
  }

  @override
  Stream<Uint8List> openRead([int? start, int? end]) {
    if (_bytes != null) {
      return _getBytes(start, end);
    } else {
      return _file.openRead(start ?? 0, end).map((List<int> chunk) => Uint8List.fromList(chunk));
    }
  }
}
''';
}

/// 原生平台数据库连接（Android / iOS / 桌面 / macOS）
///
/// 基于 drift/native 的 SQLite（sqlite3），仅在非 Web 编译时被引用。
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'anoxia_im.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

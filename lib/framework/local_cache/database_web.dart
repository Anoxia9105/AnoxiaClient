/// Web 端数据库连接
///
/// 基于 drift/wasm 的 SQLite，运行在浏览器 IndexedDB 之上。
/// 仅在 Web 编译（dart.library.html）时被引用。
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'anoxia_im',
      // 使用相对地址（不以 / 开头），使其相对 <base href> 解析，
      // 从而兼容部署在子路径（如 https://host/anoxia/）的场景。
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}

/// Web 端数据库连接
///
/// 基于 drift/wasm 的 SQLite，运行在浏览器 IndexedDB 之上。
///
/// 使用 drift 公开的 [WasmDatabase.open]：数据库运行在专用 Web Worker 中，
/// 主线程不会被同步的 SQLite I/O 阻塞，也不会出现「同步执行器 + 异步
/// IndexedDB VFS」在主线程并发读写时导致的死锁（这是此前自定义主线程托管
/// 在切换聊天室、首次对新房间做真实 DB 读写时直接卡死且无 log 的根因）。
///
/// drift 的 WasmDatabaseOpener.probe() 会在 Worker 初始化失败时捕获异常并自动
/// 回退到主线程托管（DriftServerController），因此即使在个别环境下 Worker 不可用
/// 也能正常工作，不会像早期「WasmDatabase(sqlite3, path, fileSystem)」那样挂起。
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'anoxia_im',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}

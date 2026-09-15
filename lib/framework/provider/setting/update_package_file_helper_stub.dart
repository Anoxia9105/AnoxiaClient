// 更新安装包文件操作助手（Web/WASM 空实现）
//
// 更新下载在 Web 端永远不会触发（update_download_provider 明确跳过 Web），
// 本桩仅保证 provider 可编译；所有方法抛 UnsupportedError 兜底。
Future<String> resolveUpdateSaveDir() async {
  throw UnsupportedError('update download is not supported on web');
}

Future<void> cleanupUpdateFiles(
  String dirPath, {
  String? keepName,
  Duration maxAge = const Duration(days: 7),
}) async {}

Future<int> updateFileLength(String path) async => 0;

Future<void> deleteUpdateFile(String path) async {}

Future<String> updateFileSha256Hex(String path) async => '';

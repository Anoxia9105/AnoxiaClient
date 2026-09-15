// 更新安装包文件操作助手（平台条件导出）
//
// 更新下载控制器（update_download_provider.dart）会被 Web(WASM) 编译，
// 不能直接 import dart:io。文件系统操作全部收敛到本助手：
// - 原生平台（Android / Windows / macOS / Linux）走 [_io] 实现；
// - Web 端走 [_stub]（更新下载在 Web 上永远不会触发，仅保证可编译）。
// 判定方式与 notification_helper.dart 一致：dart.library.io 仅原生为 true。
export 'update_package_file_helper_stub.dart'
    if (dart.library.io) 'update_package_file_helper_io.dart';

// 条件导出：桌面端回环接码依赖 dart:io HttpServer，Web 端不可用。
// 用 dart.library.io 判定（dart.library.html 在 WASM 下为 false，
// 详见 desktop_multi_window_shim 注释）。跨平台代码只引本文件。
export 'oauth_loopback_stub.dart'
    if (dart.library.io) 'oauth_loopback_io.dart';

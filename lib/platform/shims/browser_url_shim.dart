// 条件导出：默认 Web 实现（package:web），dart:io 平台用空实现桩。
// 用 dart.library.io 判定（dart.library.html 在 WASM 下为 false，
// 详见 desktop_multi_window_shim 注释）。跨平台代码只引本文件。
export 'browser_url_web.dart'
    if (dart.library.io) 'browser_url_stub.dart';

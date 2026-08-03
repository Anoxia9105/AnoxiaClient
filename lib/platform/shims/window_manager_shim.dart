// 条件导出：原生平台使用真实 window_manager，Web 端(JS/WASM)使用本地空实现桩。
// 用 dart.library.io 判定（dart.library.html 在 WASM 下为 false，详见 desktop_multi_window_shim 注释）。
export 'window_manager_stub.dart'
    if (dart.library.io) 'package:window_manager/window_manager.dart';

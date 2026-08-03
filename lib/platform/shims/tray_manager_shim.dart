// 条件导出：原生平台使用真实 tray_manager，Web 端(JS/WASM)使用本地空实现桩。
// 用 dart.library.io 判定（dart.library.html 在 WASM 下为 false，详见 desktop_multi_window_shim 注释）。
export 'tray_manager_stub.dart'
    if (dart.library.io) 'package:tray_manager/tray_manager.dart';

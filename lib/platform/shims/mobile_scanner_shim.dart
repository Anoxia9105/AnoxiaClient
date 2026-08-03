// 条件导出：原生平台使用真实 mobile_scanner，Web 端(JS/WASM)使用本地桩（显示不支持提示）。
// 用 dart.library.io 判定（dart.library.html 在 WASM 下为 false，详见 desktop_multi_window_shim 注释）。
export 'mobile_scanner_stub.dart'
    if (dart.library.io) 'package:mobile_scanner/mobile_scanner.dart';

// 开机自启能力：原生平台（Windows/Linux/macOS）使用真实实现，Web 端(JS/WASM)使用空实现桩。
// 用 dart.library.io 判定（dart.library.html 在 WASM 下为 false，详见 window_manager_shim 注释）。
export 'auto_start_stub.dart' if (dart.library.io) 'auto_start_io.dart';

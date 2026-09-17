// 条件导出：Web 端(JS/WASM)读取 window.isSecureContext，原生端恒为 true。
// 用 dart.library.io 判定（dart.library.html 在 WASM 下为 false）。
export 'secure_context_web.dart' if (dart.library.io) 'secure_context_io.dart';

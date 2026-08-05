// 条件导出：Web 端(JS/WASM)读取浏览器 navigator.language，原生端读取系统语言。
// 用 dart.library.io 判定（dart.library.html 在 WASM 下为 false，
// 详见 desktop_multi_window_shim 注释）。
export 'system_locale_web.dart' if (dart.library.io) 'system_locale_io.dart';

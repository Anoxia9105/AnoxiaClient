// 条件导出：Web 端(JS/WASM)使用浏览器下载实现，原生平台使用桩。
// 用 dart.library.io 判定（dart.library.html 在 WASM 下为 false，
// 详见 desktop_multi_window_shim 注释）。
export 'web_download_web.dart'
    if (dart.library.io) 'web_download_stub.dart';
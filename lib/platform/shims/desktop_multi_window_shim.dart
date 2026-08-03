// 条件导出：原生桌面平台使用真实 desktop_multi_window，Web 端(JS/WASM)使用本地空实现桩。
// 用 dart.library.io 判定平台：dart.library.html 仅 JS 版 Web 为 true、WASM 版为 false，
// 会把原生实现错编进 WASM 触发 Platform._operatingSystem；dart.library.io 在原生为 true、
// 两种 Web 均为 false，故 Web(JS/WASM) 都走 stub。
export 'desktop_multi_window_stub.dart'
    if (dart.library.io) 'package:desktop_multi_window/desktop_multi_window.dart';

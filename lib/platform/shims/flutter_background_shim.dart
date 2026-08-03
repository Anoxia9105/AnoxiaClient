// 条件导出：原生平台使用真实 flutter_background，Web 端(JS/WASM)使用本地桩（以 `rtc` 别名导入）。
// 用 dart.library.io 判定（dart.library.html 在 WASM 下为 false，详见 desktop_multi_window_shim 注释）。
export 'flutter_background_stub.dart'
    if (dart.library.io) 'package:flutter_background/flutter_background.dart';

// 条件导出：原生平台使用真实 image_gallery_saver_plus，Web 端(JS/WASM)使用本地桩。
// 用 dart.library.io 判定（dart.library.html 在 WASM 下为 false，详见 desktop_multi_window_shim 注释）。
export 'image_gallery_saver_plus_stub.dart'
    if (dart.library.io) 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

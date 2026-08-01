/// 扫码组件条件导出。
///
/// 原生平台使用 mobile_scanner 实现；Web 端使用摄像头 + Shape Detection API
/// （BarcodeDetector）实现实时二维码识别。调用方无需关心平台差异。
// 用 dart.library.io 判定（dart.library.html 在 WASM 下为 false，详见 shims/desktop_multi_window_shim 注释）。
export 'qr_scanner_web.dart' if (dart.library.io) 'qr_scanner_io.dart';

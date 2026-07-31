/// 扫码组件条件导出。
///
/// 原生平台使用 mobile_scanner 实现；Web 端使用摄像头 + Shape Detection API
/// （BarcodeDetector）实现实时二维码识别。调用方无需关心平台差异。
export 'qr_scanner_io.dart' if (dart.library.html) 'qr_scanner_web.dart';

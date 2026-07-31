// 条件导出：原生平台使用真实 mobile_scanner，Web 端使用本地桩（显示不支持提示）。
export 'package:mobile_scanner/mobile_scanner.dart'
    if (dart.library.html) 'mobile_scanner_stub.dart';

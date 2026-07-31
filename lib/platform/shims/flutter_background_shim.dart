// 条件导出：原生平台使用真实 flutter_background，Web 端使用本地桩（以 `rtc` 别名导入）。
export 'package:flutter_background/flutter_background.dart'
    if (dart.library.html) 'flutter_background_stub.dart';

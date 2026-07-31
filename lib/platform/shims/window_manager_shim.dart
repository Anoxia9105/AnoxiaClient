// 条件导出：原生平台使用真实 window_manager，Web 端使用本地空实现桩。
export 'package:window_manager/window_manager.dart'
    if (dart.library.html) 'window_manager_stub.dart';

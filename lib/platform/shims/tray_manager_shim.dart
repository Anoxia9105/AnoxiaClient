// 条件导出：原生平台使用真实 tray_manager，Web 端使用本地空实现桩。
export 'package:tray_manager/tray_manager.dart'
    if (dart.library.html) 'tray_manager_stub.dart';

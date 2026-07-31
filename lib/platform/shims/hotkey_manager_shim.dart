// 条件导出：原生桌面平台使用真实 hotkey_manager，Web 端使用本地空实现桩。
export 'package:hotkey_manager/hotkey_manager.dart'
    if (dart.library.html) 'hotkey_manager_stub.dart';

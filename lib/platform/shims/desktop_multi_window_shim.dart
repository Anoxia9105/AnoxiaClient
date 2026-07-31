// 条件导出：原生桌面平台使用真实 desktop_multi_window，Web 端使用本地空实现桩。
export 'package:desktop_multi_window/desktop_multi_window.dart'
    if (dart.library.html) 'desktop_multi_window_stub.dart';

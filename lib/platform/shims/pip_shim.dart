// 条件导出：原生平台使用真实 pip，Web 端使用本地桩。
export 'package:pip/pip.dart' if (dart.library.html) 'pip_stub.dart';

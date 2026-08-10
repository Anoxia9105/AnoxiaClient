import 'package:flutter/foundation.dart';

/// 轻量日志：委托 [debugPrint] 输出。
///
/// debugPrint 内部由 assert 包裹，release 构建完全零开销；
/// 保留调用点便于开发期排查问题，生产环境自动静默。
/// 同步失败等业务诊断数据请走数据库（logSyncFailure），不要依赖控制台日志。
void debugLog(Object message, [Object? error, Object? stackTrace]) {
  final errorText = error == null ? '' : ' $error';
  final stackText = stackTrace == null ? '' : ' $stackTrace';
  debugPrint('$message$errorText$stackText');
}
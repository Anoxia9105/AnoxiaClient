import 'package:flutter/foundation.dart';

/// 轻量日志：委托 [debugPrint] 输出。
///
/// 仅在 debug 构建生效；profile/release 构建直接返回（kDebugMode 为编译期常量），
/// 避免控制台 I/O 带来的性能开销。
/// 同步失败等业务诊断数据请走数据库（logSyncFailure），不要依赖控制台日志。
void debugLog(Object message, [Object? error, Object? stackTrace]) {
  if (!kDebugMode) {
    return;
  }
  final errorText = error == null ? '' : ' $error';
  final stackText = stackTrace == null ? '' : ' $stackTrace';
  debugPrint('$message$errorText$stackText');
}

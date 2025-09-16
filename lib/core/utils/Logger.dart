/// TODO 描述
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  10:23
class Logger {
  static void d(String tag, String message) {
    // 可替换为更复杂的日志方案（sentry, logstash）
    // ignore: avoid_print
    print('[DEBUG] $tag: $message');
  }

  static void e(String tag, Object error) {
    // ignore: avoid_print
    print('[ERROR] $tag: $error');
  }
}

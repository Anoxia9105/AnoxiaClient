// 原生端系统语言实现：读取 dart:io Platform.localeName。
import 'dart:io';

class SystemLocale {
  /// 返回系统语言代码（zh / ja / en），获取失败时返回 null。
  static String? languageCode() {
    try {
      return _normalize(Platform.localeName);
    } catch (_) {
      return null;
    }
  }

  /// 归一化到支持的三种语言；其余语言一律按 en 处理（与 fallbackLocale 一致）。
  ///
  /// Platform.localeName 通常是 'zh_CN' / 'ja-JP' 等语言代码，但部分 Windows
  /// 系统可能返回本地化名称（如 "Chinese (Simplified)"），这里两种形式都兼容。
  static String _normalize(String locale) {
    final lower = locale.toLowerCase();
    if (lower.startsWith('zh') || lower.contains('chinese')) return 'zh';
    if (lower.startsWith('ja') || lower.contains('japanese')) return 'ja';
    return 'en';
  }
}

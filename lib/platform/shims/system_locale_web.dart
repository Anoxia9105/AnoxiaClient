// Web 端系统语言实现：读取浏览器 navigator.language（JS/WASM 双兼容）。
//
// easy_localization 内部用 `intl_standalone if (dart.library.html) intl_browser`
// 检测设备语言，而 WASM 下 dart.library.html 为 false，会走到 intl_standalone
// 的 dart:io 分支——Web 上 Platform.localeName 抛异常被吞掉后 Intl.systemLocale
// 恒为默认 'en_US'，导致界面永远回退英文。这里绕开该检测链，直接读浏览器语言。
import 'package:web/web.dart' as web;

class SystemLocale {
  /// 返回系统/浏览器语言代码（zh / ja / en），获取失败时返回 null。
  static String? languageCode() {
    try {
      final language = web.window.navigator.language;
      if (language.isEmpty) return null;
      return _normalize(language);
    } catch (_) {
      return null;
    }
  }

  /// 归一化到支持的三种语言；其余语言一律按 en 处理（与 fallbackLocale 一致）。
  static String _normalize(String locale) {
    final lower = locale.toLowerCase();
    if (lower.startsWith('zh')) return 'zh';
    if (lower.startsWith('ja')) return 'ja';
    return 'en';
  }
}

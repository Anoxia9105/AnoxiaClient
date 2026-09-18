// 非 Web 平台桩：没有浏览器地址栏，一律空实现。
abstract final class BrowserUrl {
  /// 去掉地址栏 query；非 Web 平台无操作。
  static void clearQueryParameters() {}
}

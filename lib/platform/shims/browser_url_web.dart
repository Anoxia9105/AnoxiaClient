// Web 端地址栏实现：package:web + dart:js_interop（JS/WASM 双兼容），
// 不使用 dart:html（dart:html 在 --wasm(dart2wasm) 下无法编译）。
import 'package:web/web.dart' as web;

/// 浏览器地址栏小操作（Web 生效，其它平台见 stub 空实现）。
abstract final class BrowserUrl {
  /// 去掉地址栏 query（replaceState，不产生新历史记录）。
  ///
  /// Google OAuth 回调 code 只能用一次，消费后立即清理，防止刷新页
  /// 面/路由重建时被重复消费。hash 路由的 fragment 原样保留。
  static void clearQueryParameters() {
    try {
      final location = web.window.location;
      web.window.history.replaceState(
        null,
        '',
        '${location.origin}${location.pathname}${location.hash}',
      );
    } catch (_) {
      // 地址栏不可写时忽略（如非安全上下文的极端情况）。
    }
  }
}

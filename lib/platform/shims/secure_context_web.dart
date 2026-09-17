// Web 端安全上下文判定：flutter_secure_storage Web 实现仅在安全上下文
//（https / localhost / 127.0.0.1）下可用，http 公网 IP 会抛
// Unsupported operation: FlutterSecureStorageWeb only works in secure contexts。
// 这里直接读浏览器 window.isSecureContext（JS/WASM 双兼容），不使用 dart:html。
import 'package:web/web.dart' as web;

/// Web 安全上下文判定。
class SecureContext {
  /// 当前页面是否为安全上下文；获取失败时按非安全处理（走降级存储）。
  static bool get isSecureContext {
    try {
      return web.window.isSecureContext;
    } catch (_) {
      return false;
    }
  }
}

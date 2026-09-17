// 原生端安全上下文判定：原生平台走 Keychain/Keystore，不存在 Web 的
// Secure Context 限制，一律视为安全，直接使用 flutter_secure_storage。
class SecureContext {
  static bool get isSecureContext => true;
}

// 非 IO 平台桩：桌面回环接码不可用，调用即抛。
class OAuthLoopbackResult {
  final String code;
  final String state;

  const OAuthLoopbackResult({required this.code, required this.state});
}

/// 用户主动取消/关闭浏览器等待。
class OAuthCancelledException implements Exception {
  final String message;
  const OAuthCancelledException([this.message = '已取消 Google 登录']);

  @override
  String toString() => message;
}

/// 回环层失败（端口被占/打不开浏览器/state 校验失败等）。
///
/// 携带 i18n key（[messageKey]），调用方直接 `.tr()` 展示；与后端换 token
/// 失败区分开——后者已由 AuthController 统一 Toast，调用方不再重复提示。
class OAuthLoopbackException implements Exception {
  final String messageKey;
  const OAuthLoopbackException(this.messageKey);

  @override
  String toString() => messageKey;
}

abstract final class OAuthLoopback {
  /// 拉起系统浏览器完成授权，并在本地回环等待 Google 回调。
  ///
  /// 非 IO 平台不可用，始终抛 [UnsupportedError]。
  static Future<OAuthLoopbackResult> waitForCallback({
    required Uri authorizeUri,
    required String expectedState,
  }) {
    throw UnsupportedError('当前平台不支持桌面回环 OAuth 登录');
  }
}

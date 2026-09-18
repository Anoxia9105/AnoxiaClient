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

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../common/constants/oauth.dart';

/// Google OAuth 纯 Dart 助手（Web/桌面共用，无原生插件依赖）。
///
/// PKCE + state 全在此生成；浏览器拉起与回调接收按平台分流：
/// - Web：调用方用 url_launcher 同标签页跳转，Google 回调同源
///   `/oauth-callback` 由路由页处理；
/// - 桌面：调用方经 `oauth_loopback_shim` 在本地回环接码。
/// code 换 token 永远走服务端 `POST /login/oauth`，本层不碰密钥。
class GoogleOAuthService {
  GoogleOAuthService._();

  static final Random _random = Random.secure();

  /// PKCE code_verifier：43~128 字符的 base64url 随机串。
  static String generateCodeVerifier() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// PKCE code_challenge（S256）。
  static String codeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// CSRF 防护 state。
  static String generateState() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// 拼 Google 授权 URL。
  static Uri buildAuthorizeUri({
    required String redirectUri,
    required String codeChallenge,
    required String state,
  }) {
    return Uri.parse(GoogleOAuthConfig.authorizeEndpoint).replace(
      queryParameters: {
        'client_id': GoogleOAuthConfig.clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': GoogleOAuthConfig.scopes,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
        'access_type': 'online',
        'prompt': 'select_account',
      },
    );
  }
}

/// Google 回调解析结果。
class GoogleOAuthCallback {
  final String? code;
  final String? state;
  final String? error;

  const GoogleOAuthCallback({this.code, this.state, this.error});

  bool get isSuccess => code != null && code!.isNotEmpty;

  bool get isCancelled => !isSuccess;

  /// 解析授权回调的 query（Web 路由页与桌面回环共用同一语义）。
  static GoogleOAuthCallback parse(Uri uri) {
    final params = uri.queryParameters;
    return GoogleOAuthCallback(
      code: params['code'],
      state: params['state'],
      error: params['error'] ?? params['error_description'],
    );
  }
}

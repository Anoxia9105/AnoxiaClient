import 'package:anoxia/framework/core/google_oauth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleOAuth PKCE', () {
    test('已知向量：challenge 计算正确（已用 openssl/python 交叉验证）', () {
      const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
      expect(
        GoogleOAuthService.codeChallenge(verifier),
        'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
      );
    });

    test('verifier 为 43 位无填充 base64url', () {
      final verifier = GoogleOAuthService.generateCodeVerifier();
      expect(verifier.length, 43);
      expect(verifier.contains('='), isFalse);
      expect(RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(verifier), isTrue);
    });

    test('state 每次随机且为无填充 base64url', () {
      final a = GoogleOAuthService.generateState();
      final b = GoogleOAuthService.generateState();
      expect(a, isNot(equals(b)));
      expect(RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(a), isTrue);
    });
  });

  group('GoogleOAuth 授权 URL', () {
    test('含 PKCE S256 必填参数', () {
      final uri = GoogleOAuthService.buildAuthorizeUri(
        redirectUri: 'http://127.0.0.1:8080/oauth-callback',
        codeChallenge: 'challenge',
        state: 'state',
      );
      expect(uri.host, 'accounts.google.com');
      expect(uri.queryParameters['response_type'], 'code');
      expect(uri.queryParameters['code_challenge_method'], 'S256');
      expect(uri.queryParameters['code_challenge'], 'challenge');
      expect(uri.queryParameters['state'], 'state');
      expect(
        uri.queryParameters['redirect_uri'],
        'http://127.0.0.1:8080/oauth-callback',
      );
      expect(uri.queryParameters['scope'], contains('openid'));
      // client_id 缺配置时为空串，由 UI 层提前拦截，不在此抛异常
      expect(uri.queryParameters.containsKey('client_id'), isTrue);
    });
  });

  group('GoogleOAuth 回调解析', () {
    test('成功回调解析出 code/state', () {
      final result = GoogleOAuthCallback.parse(
        Uri.parse('https://chat.anoxia.cn/oauth-callback?code=abc&state=xyz'),
      );
      expect(result.isSuccess, isTrue);
      expect(result.code, 'abc');
      expect(result.state, 'xyz');
    });

    test('用户拒绝解析为取消', () {
      final result = GoogleOAuthCallback.parse(
        Uri.parse(
          'https://chat.anoxia.cn/oauth-callback?error=access_denied',
        ),
      );
      expect(result.isSuccess, isFalse);
      expect(result.isCancelled, isTrue);
      expect(result.error, 'access_denied');
    });
  });
}

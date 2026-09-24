import 'package:anoxia/framework/provider/router/login_route_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('未登录入口路由策略', () {
    test('退出后存在快捷登录账号时进入快捷登录页', () {
      expect(
        resolveUnauthenticatedRedirect(
          location: '/',
          manualLogin: false,
          passwordLoginRequested: false,
          hasQuickLoginAccount: true,
        ),
        '/quick-login',
      );
    });

    test('用户明确选择普通登录时停留在登录页', () {
      expect(
        resolveUnauthenticatedRedirect(
          location: '/login',
          manualLogin: true,
          passwordLoginRequested: false,
          hasQuickLoginAccount: true,
        ),
        isNull,
      );
    });

    test('从普通登录返回快捷登录时允许进入快捷登录页', () {
      expect(
        resolveUnauthenticatedRedirect(
          location: '/quick-login',
          manualLogin: false,
          passwordLoginRequested: false,
          hasQuickLoginAccount: true,
        ),
        isNull,
      );
    });

    test('快捷凭据失效后优先进入已预填账号的密码登录页', () {
      expect(
        resolveUnauthenticatedRedirect(
          location: '/quick-login',
          manualLogin: false,
          passwordLoginRequested: true,
          hasQuickLoginAccount: false,
        ),
        '/login',
      );
    });
  });
}

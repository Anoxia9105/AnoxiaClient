const loginLocation = '/login';
const quickLoginLocation = '/quick-login';

/// 未登录状态下决定登录入口。
///
/// 用户明确选择密码登录、或快捷凭据失效需要预填账号时，保留普通登录页；
/// 其他情况下只要存在可用的设备凭据，就优先展示快捷登录页。
String? resolveUnauthenticatedRedirect({
  required String location,
  required bool manualLogin,
  required bool passwordLoginRequested,
  required bool hasQuickLoginAccount,
}) {
  final isLogin = location == loginLocation;
  final isQuickLogin = location == quickLoginLocation;

  if (isLogin && (manualLogin || passwordLoginRequested)) return null;
  if (passwordLoginRequested) return loginLocation;
  if (hasQuickLoginAccount) {
    return isQuickLogin ? null : quickLoginLocation;
  }
  return isLogin ? null : loginLocation;
}

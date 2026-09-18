import 'package:anoxia/platform/shims/runtime_config_shim.dart';

/// OAuth 第三方登录常量（首期仅 Google，供 Web/桌面端使用）。
///
/// Client ID 是公开信息（授权 URL 里明文携带），解析优先级：
/// Web 端部署注入（runtime-config.js `googleClientId`，Docker 由
/// `GOOGLE_OAUTH_CLIENT_ID` 渲染）→ 编译期 `--dart-define=GOOGLE_OAUTH_CLIENT_ID`。
/// 为空表示未配置，UI 层隐藏 Google 登录入口并提示联系管理员。
class GoogleOAuthConfig {
  /// 编译期注入：`flutter build ... --dart-define=GOOGLE_OAUTH_CLIENT_ID=xxx.apps.googleusercontent.com`
  static const String _dartDefineClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_ID',
  );

  static String get clientId {
    final runtime = RuntimeConfigOverrides.googleClientId;
    if (runtime != null && runtime.trim().isNotEmpty) return runtime.trim();
    return _dartDefineClientId.trim();
  }

  static bool get isConfigured => clientId.isNotEmpty;

  /// Google 授权端点（token 交换在服务端完成，前端不到这一步）。
  static const String authorizeEndpoint =
      'https://accounts.google.com/o/oauth2/v2/auth';

  /// 固定请求身份 + 邮箱 + 公开资料（基础 scope，免 Google 审核）。
  static const String scopes = 'openid email profile';

  /// Web 端回调：同源 `/oauth-callback`（须与 Google 控制台注册完全一致）。
  static String webRedirectUri(Uri base) => '${base.origin}/oauth-callback';

  /// 桌面端回调：本地回环固定端口（须与 Google 控制台注册完全一致）。
  static const String desktopRedirectUri =
      'http://127.0.0.1:8080/oauth-callback';

  /// 桌面回环监听端口（与 [desktopRedirectUri] 保持一致）。
  static const int desktopLoopbackPort = 8080;
}

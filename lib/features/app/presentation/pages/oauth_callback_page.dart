import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:anoxia/common/constants/oauth.dart';
import 'package:anoxia/common/constants/storage_keys.dart';
import 'package:anoxia/common/utils/sp_util.dart';
import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/framework/core/google_oauth_service.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/core/app_initializer.dart';

/// Web 端 Google OAuth 回调页（桌面端走本地回环，不经过本页）。
///
/// Google 按注册的重定向 URI 跳回同源 `/oauth-callback?code=...&state=...`，
/// 本页读回跳转前暂存的 PKCE verifier/state，校验后调 OAuth 登录，
/// 成功后路由守卫自动送往首页（与密码登录一致）。
class OAuthCallbackPage extends ConsumerStatefulWidget {
  const OAuthCallbackPage({super.key});

  @override
  ConsumerState<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends ConsumerState<OAuthCallbackPage> {
  String? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleCallback());
  }

  Future<void> _handleCallback() async {
    // 整页跳转回来后一次性消费暂存，防重放。
    final verifier = SPUtil.instance.get(StorageKeys.oauthCodeVerifier);
    final savedState = SPUtil.instance.get(StorageKeys.oauthState);
    await SPUtil.instance.deleteMulti([
      StorageKeys.oauthCodeVerifier,
      StorageKeys.oauthState,
    ]);

    final callback = GoogleOAuthCallback.parse(Uri.base);
    if (!callback.isSuccess) {
      _fail('login_oauth_cancelled'.tr());
      return;
    }
    if (verifier == null || verifier.isEmpty) {
      _fail('login_oauth_expired'.tr());
      return;
    }
    if (savedState == null || callback.state != savedState) {
      _fail('login_oauth_state_mismatch'.tr());
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).loginWithOAuth(
            provider: 'google',
            code: callback.code!,
            codeVerifier: verifier,
            redirectUri: GoogleOAuthConfig.webRedirectUri(Uri.base),
          );
      final user = ref.read(authControllerProvider).value;
      if (user == null) {
        _fail('login_failed'.tr());
        return;
      }
      if (!mounted) return;
      setState(() => _done = true);
      await ref.read(appInitializerProvider.notifier).performFullReset();
    } catch (_) {
      // 错误文案已由 AuthController 统一 Toast，此处只保留页面态。
      if (!mounted) return;
      _fail('login_failed'.tr());
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppScaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error == null) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    (_done
                            ? 'login_oauth_success'
                            : 'login_oauth_callback_loading')
                        .tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ] else ...[
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    child: Text('login_oauth_back_to_login'.tr()),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

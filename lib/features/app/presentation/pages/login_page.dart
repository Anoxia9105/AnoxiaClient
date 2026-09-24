import 'dart:async';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/constants/oauth.dart';
import 'package:anoxia/common/constants/storage_keys.dart';
import 'package:anoxia/common/utils/sp_util.dart';
import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/framework/core/google_oauth_service.dart';
import 'package:anoxia/platform/shims/browser_url_shim.dart';
import 'package:anoxia/platform/shims/oauth_loopback_shim.dart';
import 'package:anoxia/features/app/presentation/widgets/google_g_icon.dart';
import 'package:anoxia/features/app/presentation/pages/forgot_password_page.dart';
import 'package:anoxia/features/app/presentation/pages/register_page.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/auth/saved_accounts_provider.dart';
import 'package:anoxia/framework/provider/core/app_initializer.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'login_captcha.dart';
import 'login_scan_panel.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 登录页面
///
/// 提供用户登录功能，包含用户名、密码和验证码输入。
/// 自适应桌面端与移动端屏幕，防止键盘弹起时视图溢出并提供安全的边距填充。
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  /// 用户名输入控制器
  final _usernameCtrl = TextEditingController();

  /// 密码输入控制器
  final _passwordCtrl = TextEditingController();

  /// 验证码输入控制器
  final _codeCtrl = TextEditingController();

  /// 是否隐藏密码
  bool _obscurePassword = true;

  /// 是否正在执行登录操作
  bool _isLoading = false;

  /// 是否正在执行 Google 登录
  bool _isOAuthLoading = false;

  /// 当前登录方式（仅桌面/Web 展示扫码登录）
  _LoginMode _mode = _LoginMode.password;

  /// 是否展示扫码登录入口（手机端扫码确认入口在 App 内）
  bool get _showScanMode => !DeviceUtil.isRealMobile();

  /// 是否展示 Google 登录（首期仅 Web/桌面开放；移动端保留密码登录）
  bool get _showOAuthLogin =>
      (DeviceUtil.isRealWeb() || DeviceUtil.isRealDesktop()) &&
      GoogleOAuthConfig.isConfigured;

  @override
  void initState() {
    super.initState();
    // 切换账号遇 token 过期降级到登录页时，预填目标账号名（消费后立即清空）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prefill = ref.read(loginPrefillAccountProvider);
      if (prefill != null && prefill.isNotEmpty) {
        _usernameCtrl.text = prefill;
        ref.read(loginPrefillAccountProvider.notifier).set(null);
      }
      // Web 端 Google 回调：hash 路由下 Google 只能回到 path，路由页挂载不上，
      // code 会留在地址栏 query 里，由登录页认领完成换 token（见方法注释）。
      _handleWebOAuthReturn();
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final loginMutation = ref.watch(AuthController.loginMutation);

    return AppScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // 确保至少和屏幕等高，方便内容少时可以垂直居中
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                // 确保在滚动视图内部依然整体居中
                child: Padding(
                  // 移动端/窄屏时，两边自动留出 24 逻辑像素的内填充，不再紧贴边缘
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    // 限制最大宽度，桌面端/宽屏下保持 400 宽居中
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(colorScheme, textTheme),
                        const SizedBox(height: 36),
                        // 密码 / 扫码 两种登录方式独立成视图，切换时平滑过渡
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.98,
                                  end: 1.0,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _mode == _LoginMode.scan
                              ? _buildScanView(colorScheme)
                              : _buildPasswordView(colorScheme, loginMutation),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 密码登录视图（仅展示密码表单；桌面/Web 底部提供切到扫码登录的入口）
  Widget _buildPasswordView(
    ColorScheme colorScheme,
    MutationState<void> loginMutation,
  ) {
    final hasQuickLoginAccount =
        ref
            .watch(savedAccountsServiceProvider)
            .value
            ?.any((account) => account.quickLoginCredential.isNotEmpty) ==
        true;
    return Column(
      key: const ValueKey(_LoginMode.password),
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUsernameField(colorScheme),
            const SizedBox(height: 16),
            _buildPasswordField(colorScheme),
            const SizedBox(height: 16),
            _buildCaptchaField(colorScheme),
            const SizedBox(height: 28),
            _buildLoginButton(colorScheme, loginMutation),
          ],
        ),
        const SizedBox(height: 20),
        _buildFooterLinks(colorScheme),
        if (hasQuickLoginAccount) _buildSwitchToQuickLogin(colorScheme),
        if (DeviceUtil.isRealWeb() &&
            ref.watch(guestLoginEnabledProvider).value == true)
          _buildGuestLogin(colorScheme),
        if (_showOAuthLogin) _buildOAuthSection(colorScheme),
        if (_showScanMode) _buildSwitchToScan(colorScheme),
      ],
    );
  }

  Widget _buildSwitchToQuickLogin(ColorScheme colorScheme) {
    return TextButton.icon(
      onPressed: _isLoading ? null : () => context.go('/quick-login'),
      icon: const Icon(Icons.flash_on_outlined, size: 18),
      label: Text('quick_login_switch_to_saved'.tr()),
      style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
    );
  }

  /// 扫码登录视图（仅展示二维码；桌面/Web 底部提供切到密码登录的入口）
  Widget _buildScanView(ColorScheme colorScheme) {
    return Column(
      key: const ValueKey(_LoginMode.scan),
      mainAxisSize: MainAxisSize.min,
      children: [
        const ScanLoginPanel(),
        if (_showScanMode) _buildSwitchToPassword(colorScheme),
      ],
    );
  }

  /// 登录方式分隔线（居中“或”）
  Widget _buildModeDivider(ColorScheme colorScheme) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'login_scan_or'.tr(),
            style: Theme.of(context).textTheme.bodySmall!.copyWith( color: colorScheme.onSurfaceVariant),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  /// 切换到扫码登录的入口
  Widget _buildSwitchToScan(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        _buildModeDivider(colorScheme),
        TextButton.icon(
          onPressed: () => setState(() => _mode = _LoginMode.scan),
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedQrCode01, size: 18),
          label: Text('login_scan_switch_to_scan'.tr()),
          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
        ),
      ],
    );
  }

  /// 切换到密码登录的入口
  Widget _buildSwitchToPassword(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        _buildModeDivider(colorScheme),
        TextButton.icon(
          onPressed: () => setState(() => _mode = _LoginMode.password),
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedKey02, size: 18),
          label: Text('login_scan_switch_to_password'.tr()),
          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RadiusToken.xl),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(RadiusToken.xl),
            clipBehavior: Clip.antiAlias,
            child: Assets.images.appLogo.image(
              width: 72,
              height: 72,
              fit: BoxFit.contain,
              isAntiAlias: true,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'login_page_title'.tr(),
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField(ColorScheme colorScheme) {
    return TextField(
      controller: _usernameCtrl,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.username, AutofillHints.email],
      inputFormatters: [LengthLimitingTextInputFormatter(60)],
      decoration: InputDecoration(
        hintText: 'login_page_account_or_email'.tr(),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedAt,
            color: colorScheme.onSurfaceVariant,
            size: 14,
          ),
        ),
        prefixIconConstraints: const BoxConstraints.tightFor(
          width: 36,
          height: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(RadiusToken.md)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusToken.md),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusToken.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField(ColorScheme colorScheme) {
    return TextField(
      controller: _passwordCtrl,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      inputFormatters: [LengthLimitingTextInputFormatter(50)],
      // 使用默认的圆点遮蔽字符（与注册/找回密码页保持一致）。
      // JetBrainsMono 的 `*` 字形本身偏上（yMin 103 / yMax 620，见字体
      // 度量），在 Web/Wasm 下与光标行高混排时第二个字符看起来会被「挤上去」，
      // 换成默认圆点后垂直居中，不再出现该观感问题。
      decoration: InputDecoration(
        hintText: 'login_page_password'.tr(),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedLock,
            color: colorScheme.onSurfaceVariant,
            size: 14,
          ),
        ),
        prefixIconConstraints: const BoxConstraints.tightFor(
          width: 36,
          height: 16,
        ),
        suffixIcon: IconButton(
          icon: HugeIcon(
            icon: _obscurePassword
                ? HugeIcons.strokeRoundedViewOff
                : HugeIcons.strokeRoundedView,
            color: colorScheme.onSurfaceVariant,
            size: 16,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(RadiusToken.md)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusToken.md),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusToken.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildCaptchaField(ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _codeCtrl,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
            inputFormatters: [
              LengthLimitingTextInputFormatter(4),
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            ],
            decoration: InputDecoration(
              hintText: 'login_page_captcha'.tr(),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedShield01,
                  color: colorScheme.onSurfaceVariant,
                  size: 14,
                ),
              ),
              prefixIconConstraints: const BoxConstraints.tightFor(
                width: 36,
                height: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RadiusToken.md),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RadiusToken.md),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RadiusToken.md),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 将验证码图片提取为单独的 widget，避免焦点变化导致重新渲染
        const CaptchaImage(),
      ],
    );
  }

  Widget _buildLoginButton(
    ColorScheme colorScheme,
    MutationState<void> loginMutation,
  ) {
    final isPending = loginMutation is MutationPending;
    final isDisabled = isPending || _isLoading;

    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: isDisabled ? null : _handleLogin,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusToken.lg),
          ),
          textStyle: Theme.of(context).textTheme.titleMedium!.copyWith( fontWeight: FontWeight.w600),
        ),
        child: isDisabled
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text('login_page_login'.tr()),
      ),
    );
  }

  /// Google 登录区（Web/桌面专属，与密码登录并存；小圆形图标按钮）
  Widget _buildOAuthSection(ColorScheme colorScheme) {
    final isDisabled = _isOAuthLoading || _isLoading;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        _buildModeDivider(colorScheme),
        const SizedBox(height: 12),
        Center(
          child: Tooltip(
            message: 'login_oauth_google'.tr(),
            child: Material(
              color: colorScheme.surface,
              elevation: 1,
              shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
              shape: CircleBorder(
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isDisabled ? null : _handleGoogleLogin,
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: _isOAuthLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const GoogleGIcon(size: 22),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Google 登录总入口：按平台分流（Web 整页跳转 / 桌面本地回环）。
  Future<void> _handleGoogleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!GoogleOAuthConfig.isConfigured) {
      Toast.showToast(
        'login_oauth_not_configured'.tr(),
        type: ToastType.error,
        singleton: true,
      );
      return;
    }
    if (DeviceUtil.isRealWeb()) {
      await _handleGoogleLoginWeb();
    } else if (DeviceUtil.isRealDesktop()) {
      await _handleGoogleLoginDesktop();
    }
  }

  /// Web 端 Google 回调认领（hash 路由的锅，必须放登录页）。
  ///
  /// Web 默认 hash 路由只认 `#` 后面的 fragment，Google 按注册的重定向 URI
  /// 回到 `/oauth-callback?code=...`（无 fragment）时，Flutter 实际挂载的是
  /// 启动页→登录页，`/oauth-callback` 路由页永远上不来；code/state 则原样
  /// 留在地址栏 query 里（这正是线上 `#/login` 尾巴前面还挂着一串 code 的原因）。
  /// 这里检测到 code 就走完换 token 全程，并清掉地址栏 query 防重放。
  Future<void> _handleWebOAuthReturn() async {
    if (!DeviceUtil.isRealWeb() || _isOAuthLoading) return;
    final callback = GoogleOAuthCallback.parse(Uri.base);
    if (!callback.isSuccess) return;

    setState(() => _isOAuthLoading = true);
    try {
      // 整页跳转回来后一次性消费暂存，防重放。
      final verifier = SPUtil.instance.get(StorageKeys.oauthCodeVerifier);
      final savedState = SPUtil.instance.get(StorageKeys.oauthState);
      await SPUtil.instance.deleteMulti([
        StorageKeys.oauthCodeVerifier,
        StorageKeys.oauthState,
      ]);
      // 先清地址栏：code 只能用一次，刷新/重建时不再二次消费。
      BrowserUrl.clearQueryParameters();

      if (verifier == null || verifier.isEmpty) {
        Toast.showToast(
          'login_oauth_expired'.tr(),
          type: ToastType.error,
          singleton: true,
        );
        return;
      }
      if (savedState == null || callback.state != savedState) {
        Toast.showToast(
          'login_oauth_state_mismatch'.tr(),
          type: ToastType.error,
          singleton: true,
        );
        return;
      }
      await ref.read(authControllerProvider.notifier).loginWithOAuth(
            provider: 'google',
            code: callback.code!,
            codeVerifier: verifier,
            redirectUri: GoogleOAuthConfig.webRedirectUri(Uri.base),
          );
      final user = ref.read(authControllerProvider).value;
      if (user == null) return;
      await ref.read(appInitializerProvider.notifier).performFullReset();
    } catch (_) {
      // 后端错误已由 AuthController 统一 Toast，这里不再重复提示。
    } finally {
      if (mounted) setState(() => _isOAuthLoading = false);
    }
  }

  /// Web 流程：暂存 PKCE → 同标签页跳 Google → 回调页接码换 token。
  Future<void> _handleGoogleLoginWeb() async {
    setState(() => _isOAuthLoading = true);
    try {
      final verifier = GoogleOAuthService.generateCodeVerifier();
      final state = GoogleOAuthService.generateState();
      await SPUtil.instance.set(StorageKeys.oauthCodeVerifier, verifier);
      await SPUtil.instance.set(StorageKeys.oauthState, state);
      final authorizeUri = GoogleOAuthService.buildAuthorizeUri(
        redirectUri: GoogleOAuthConfig.webRedirectUri(Uri.base),
        codeChallenge: GoogleOAuthService.codeChallenge(verifier),
        state: state,
      );
      final launched = await launchUrl(
        authorizeUri,
        webOnlyWindowName: '_self',
      );
      if (!launched && mounted) {
        await SPUtil.instance.deleteMulti([
          StorageKeys.oauthCodeVerifier,
          StorageKeys.oauthState,
        ]);
        Toast.showToast(
          'login_oauth_open_browser_failed'.tr(),
          type: ToastType.error,
          singleton: true,
        );
      }
      // 跳转成功后整页离开，无需复位 loading。
    } catch (_) {
      if (!mounted) return;
      Toast.showToast(
        'login_oauth_failed'.tr(),
        type: ToastType.error,
        singleton: true,
      );
      if (mounted) setState(() => _isOAuthLoading = false);
    }
  }

  /// 桌面流程：本地回环接码 → 直接换 token 登录（不整页跳转）。
  Future<void> _handleGoogleLoginDesktop() async {
    setState(() => _isOAuthLoading = true);
    try {
      final verifier = GoogleOAuthService.generateCodeVerifier();
      final state = GoogleOAuthService.generateState();
      final authorizeUri = GoogleOAuthService.buildAuthorizeUri(
        redirectUri: GoogleOAuthConfig.desktopRedirectUri,
        codeChallenge: GoogleOAuthService.codeChallenge(verifier),
        state: state,
      );
      final result = await OAuthLoopback.waitForCallback(
        authorizeUri: authorizeUri,
        expectedState: state,
      );
      await ref.read(authControllerProvider.notifier).loginWithOAuth(
            provider: 'google',
            code: result.code,
            codeVerifier: verifier,
            redirectUri: GoogleOAuthConfig.desktopRedirectUri,
          );
      final user = ref.read(authControllerProvider).value;
      if (user == null) return;
      await ref.read(appInitializerProvider.notifier).performFullReset();
    } on OAuthCancelledException {
      // 用户在浏览器侧取消：静默返回登录页。
    } on OAuthLoopbackException catch (e) {
      // 回环层失败（端口被占/打不开浏览器等）：AuthController 没参与，必须这里提示。
      if (mounted) {
        Toast.showToast(
          e.messageKey.tr(),
          type: ToastType.error,
          singleton: true,
        );
      }
    } on TimeoutException {
      if (mounted) {
        Toast.showToast(
          'login_oauth_failed'.tr(),
          type: ToastType.error,
          singleton: true,
        );
      }
    } catch (_) {
      // 后端换 token 失败已由 AuthController 统一 Toast，不再重复提示。
    } finally {
      if (mounted) setState(() => _isOAuthLoading = false);
    }
  }

  Widget _buildFooterLinks(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: _showForgotPasswordDialog,
          child: Text(
            'login_page_forget'.tr(),
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
        Text('·', style: TextStyle(color: colorScheme.outline)),
        TextButton(
          onPressed: _openRegisterPage,
          child: Text(
            'login_page_register'.tr(),
            style: TextStyle(color: colorScheme.primary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestLogin(ColorScheme colorScheme) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildModeDivider(colorScheme),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _handleGuestLogin,
            child: Text('guest_login_action'.tr()),
          ),
        ),
      ],
    );
  }

  Future<void> _handleGuestLogin() async {
    setState(() => _isLoading = true);
    try {
      final firstLogin =
          await ref.read(authControllerProvider.notifier).loginAsGuest();
      if (!mounted) return;
      if (firstLogin) await _showGuestSafetyNotice();
      if (!mounted) return;
      ref.read(authControllerProvider.notifier).finishGuestLogin();
      await ref.read(appInitializerProvider.notifier).performFullReset();
    } catch (_) {
      // AuthController 已统一显示服务端错误。
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showGuestSafetyNotice() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.security_outlined),
        title: Text('guest_login_notice_title'.tr()),
        content: Text('guest_login_notice_content'.tr()),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('guest_login_notice_confirm'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
    );
    if (!mounted) return;
    if (result != null && result.trim().isNotEmpty) {
      _usernameCtrl.text = result.trim();
      _passwordCtrl.clear();
      _codeCtrl.clear();
      ref.invalidate(getCaptchaProvider);
    }
  }

  Future<void> _openRegisterPage() async {
    final account = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const RegisterPage()));
    if (!mounted || account == null || account.trim().isEmpty) return;
    _usernameCtrl.text = account.trim();
    _passwordCtrl.clear();
    _codeCtrl.clear();
    ref.invalidate(getCaptchaProvider);
  }

  Future<void> _handleLogin() async {
    // 点击登录时先收起输入法，避免键盘遮挡页面或登录后残留
    FocusManager.instance.primaryFocus?.unfocus();

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final code = _codeCtrl.text.trim();

    if (username.isEmpty) {
      Toast.showToast(
        'login_page_username_validator_notnull'.tr(),
        type: ToastType.error,
        singleton: true,
      );
      return;
    }
    if (password.isEmpty) {
      Toast.showToast(
        'login_page_password_validator_notnull'.tr(),
        type: ToastType.error,
        singleton: true,
      );
      return;
    }
    if (password.length < 5 || password.length > 50) {
      Toast.showToast(
        'login_page_password_validator_regex'.tr(),
        type: ToastType.error,
        singleton: true,
      );
      return;
    }
    if (code.isEmpty) {
      Toast.showToast(
        'login_page_captcha_validator_notnull'.tr(),
        type: ToastType.error,
        singleton: true,
      );
      return;
    }

    final captcha = ref.read(getCaptchaProvider).value;
    if (captcha == null) {
      ref.invalidate(getCaptchaProvider);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthController.loginMutation.run(ref, (ref) {
        return ref
            .get(authControllerProvider.notifier)
            .login(
              _usernameCtrl.text.trim(),
              _passwordCtrl.text.trim(),
              _codeCtrl.text.trim(),
              captcha.uuid,
            );
      });

      final user = ref.read(authControllerProvider).value;
      if (user == null) {
        _codeCtrl.clear();
        ref.invalidate(getCaptchaProvider);
        return;
      }

      await ref.read(appInitializerProvider.notifier).performFullReset();
    } catch (_) {
      _codeCtrl.clear();
      ref.invalidate(getCaptchaProvider);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// 验证码图片 Widget
///
/// 使用 Consumer 监听 provider，避免父级重建导致验证码重新渲染
/// 登录方式枚举
enum _LoginMode { password, scan }

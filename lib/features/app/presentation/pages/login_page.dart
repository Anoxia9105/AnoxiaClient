import 'dart:async';
import 'package:hugeicons/hugeicons.dart';
import 'dart:convert';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/features/app/presentation/pages/forgot_password_page.dart';
import 'package:anoxia/features/app/presentation/pages/register_page.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/auth/scan_login_controller.dart';
import 'package:anoxia/framework/provider/core/app_initializer.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
  /// 表单验证 Key
  final _formKey = GlobalKey<FormState>();

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

  /// 当前登录方式（仅桌面/Web 展示扫码登录）
  _LoginMode _mode = _LoginMode.password;

  /// 是否展示扫码登录入口（手机端扫码确认入口在 App 内）
  bool get _showScanMode => !DeviceUtil.isRealMobile();

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
    return Column(
      key: const ValueKey(_LoginMode.password),
      mainAxisSize: MainAxisSize.min,
      children: [
        Form(
          key: _formKey,
          child: Column(
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
        ),
        const SizedBox(height: 20),
        _buildFooterLinks(colorScheme),
        if (_showScanMode) _buildSwitchToScan(colorScheme),
      ],
    );
  }

  /// 扫码登录视图（仅展示二维码；桌面/Web 底部提供切到密码登录的入口）
  Widget _buildScanView(ColorScheme colorScheme) {
    return Column(
      key: const ValueKey(_LoginMode.scan),
      mainAxisSize: MainAxisSize.min,
      children: [
        const _ScanLoginPanel(),
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
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
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
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Assets.images.appLogo.image(
              fit: BoxFit.cover,
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
    return TextFormField(
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
            size: 16,
          ),
        ),
        prefixIconConstraints: const BoxConstraints.tightFor(width: 36, height: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'login_page_username_validator_notnull'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(ColorScheme colorScheme) {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      inputFormatters: [LengthLimitingTextInputFormatter(50)],
      obscuringCharacter: '*',
      decoration: InputDecoration(
        hintText: 'login_page_password'.tr(),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedLock,
            color: colorScheme.onSurfaceVariant,
            size: 16,
          ),
        ),
        prefixIconConstraints: const BoxConstraints.tightFor(width: 36, height: 16),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'login_page_password_validator_notnull'.tr();
        }
        if (value.length < 5 || value.length > 50) {
          return 'login_page_password_validator_regex'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildCaptchaField(ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _codeCtrl,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
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
                  size: 16,
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints.tightFor(width: 36, height: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'login_page_captcha_validator_notnull'.tr();
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        // 将验证码图片提取为单独的 widget，避免焦点变化导致重新渲染
        const _CaptchaImage(),
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
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
class _CaptchaImage extends ConsumerWidget {
  const _CaptchaImage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return ref
        .watch(getCaptchaProvider)
        .when(
          data: (captcha) {
            return Tooltip(
              message: 'login_page_captcha'.tr(),
              child: Material(
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                color: colorScheme.surfaceContainerHigh,
                child: InkWell(
                  onTap: () => ref.invalidate(getCaptchaProvider),
                  mouseCursor: SystemMouseCursors.click,
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 120,
                    height: 48,
                    child: Image.memory(
                      base64Decode(captcha.imgBase64),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => Container(
            width: 120,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, st) => Container(
            width: 120,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh01,
                color: colorScheme.onErrorContainer,
              ),
              onPressed: () => ref.invalidate(getCaptchaProvider),
            ),
          ),
        );
  }
}

/// 登录方式枚举
enum _LoginMode { password, scan }

/// 扫码登录面板（桌面/Web）
///
/// 展示二维码并自动轮询登录状态；手机 App 扫码确认后自动完成登录。
class _ScanLoginPanel extends ConsumerStatefulWidget {
  const _ScanLoginPanel();

  @override
  ConsumerState<_ScanLoginPanel> createState() => _ScanLoginPanelState();
}

class _ScanLoginPanelState extends ConsumerState<_ScanLoginPanel> {
  /// 倒计时定时器（每秒递减）
  Timer? _ticker;

  /// 当前倒计时所属的 ticket，ticket 变化时重置倒计时
  String? _countdownFor;

  /// 剩余有效秒数
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// 创建新的扫码登录会话
  Future<void> _startSession() async {
    try {
      await ref.read(scanLoginControllerProvider.notifier).start();
    } catch (_) {
      // 错误状态由下方 UI 展示，此处仅静默
    }
  }

  /// 启动倒计时
  void _beginCountdown(String ticket, int expiresIn) {
    _ticker?.cancel();
    setState(() {
      _countdownFor = ticket;
      _remaining = expiresIn;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0) {
        setState(() => _remaining -= 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final session = ref.watch(scanLoginControllerProvider);

    return session.when(
      loading: () => _buildLoading(),
      error: (e, st) => _buildError(colorScheme),
      data: (session) {
        if (session == null) return _buildLoading();

        final ticket = session.ticket;
        if (_countdownFor != ticket.ticket) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _beginCountdown(ticket.ticket, ticket.expiresIn),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQrCard(colorScheme, session),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'login_scan_countdown'.tr(namedArgs: {'seconds': '$_remaining'}),
                  style: TextStyle(
                    fontSize: 13,
                    color: _remaining <= 10
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: _startSession,
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh01, size: 18),
                  label: Text('login_scan_refresh'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'login_scan_hint'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQrCard(ColorScheme colorScheme, ScanLoginSession session) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: QrImageView(
          data: session.ticket.qrContent,
          size: 200,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Colors.black,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  /// 加载中骨架屏（布局与二维码卡片一致）
  Widget _buildLoading() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QrSkeleton(),
        SizedBox(height: 18),
        SkeletonLine(width: 120, height: 12),
        SizedBox(height: 14),
        SkeletonLine(width: 170, height: 10),
      ],
    );
  }

  Widget _buildError(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: HugeIcons.strokeRoundedAlertCircle, size: 48, color: colorScheme.error),
        const SizedBox(height: 12),
        Text(
          'login_scan_error'.tr(),
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _startSession,
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh01, size: 18),
          label: Text('login_scan_retry'.tr()),
        ),
      ],
    );
  }
}

/// 扫码登录骨架屏
///
/// 布局与真实二维码卡片一致：三个角落的寻像图形 + 中部数据模块占位。
class _QrSkeleton extends StatelessWidget {
  const _QrSkeleton();

  /// 模拟数据模块的位置（相对卡片内边距区域）
  static const List<Offset> _dots = [
    Offset(60, 60),
    Offset(88, 60),
    Offset(116, 60),
    Offset(60, 88),
    Offset(116, 88),
    Offset(60, 116),
    Offset(88, 116),
    Offset(116, 116),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 224,
      height: 224,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Stack(
        children: [
          const Positioned(left: 0, top: 0, child: _QrFinderPattern()),
          const Positioned(right: 0, top: 0, child: _QrFinderPattern()),
          const Positioned(left: 0, bottom: 0, child: _QrFinderPattern()),
          for (final offset in _dots)
            Positioned(
              left: offset.dx,
              top: offset.dy,
              child: const SkeletonBox(width: 12, height: 12, radius: 3),
            ),
          const Positioned(right: 0, bottom: 0, child: _QrAlignmentPattern()),
        ],
      ),
    );
  }
}

/// 二维码寻像图形（三个角落的“回”字占位）
class _QrFinderPattern extends StatelessWidget {
  const _QrFinderPattern();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SkeletonBox(width: 44, height: 44, radius: 8),
          SkeletonBox(width: 22, height: 22, radius: 4),
        ],
      ),
    );
  }
}

/// 二维码对齐图形（右下角小“回”字占位）
class _QrAlignmentPattern extends StatelessWidget {
  const _QrAlignmentPattern();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 27,
      height: 27,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SkeletonBox(width: 27, height: 27, radius: 6),
          SkeletonBox(width: 11, height: 11, radius: 3),
        ],
      ),
    );
  }
}

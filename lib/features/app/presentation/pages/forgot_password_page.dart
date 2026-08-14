// 忘记密码页面，提供两步找回流程：邮箱验证和密码重置。
//
// 第一步输入邮箱并通过图形验证码发送邮箱验证码，验证通过后进入第二步设置新密码。
import 'dart:async';
import 'package:hugeicons/hugeicons.dart';
import 'dart:convert';

import 'package:anoxia/common/utils/validators.dart';
import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 忘记密码页面
///
/// 使用 Riverpod 管理状态，支持两步找回流程：先通过图形验证码获取邮箱验证码并验证邮箱，
/// 验证通过后设置新密码完成重置。验证码图片高度与输入框保持一致。
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

/// 忘记密码页面状态
///
/// 管理邮箱、图形验证码、邮箱验证码、新密码等输入框的控制器，
/// 以及发送/验证/提交状态和倒计时逻辑。
class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  /// 验证码容器高度，与输入框高度保持一致
  static const double _captchaHeight = 44;

  final _emailCtrl = TextEditingController();
  final _captchaCtrl = TextEditingController();
  final _emailCodeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isSendingCode = false;
  bool _isVerifyingEmail = false;
  bool _isSubmitting = false;
  bool _isCaptchaHovering = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _countdown = 0;
  Timer? _countdownTimer;
  String? _resetToken;
  _SimpleCaptchaData? _captcha;

  bool get _emailVerified => _resetToken != null;

  @override
  void initState() {
    super.initState();
    _loadCaptcha();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailCtrl.dispose();
    _captchaCtrl.dispose();
    _emailCodeCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(colorScheme),
                        const SizedBox(height: 22),
                        _buildSteps(colorScheme),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _emailVerified
                              ? _buildPasswordStep(colorScheme)
                              : _buildEmailStep(colorScheme),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) => SizedBox(
    height: 52,
    child: Row(
      children: [
        IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            if (_emailVerified) {
              setState(() => _resetToken = null);
            } else {
              Navigator.of(context).pop();
            }
          },
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
        ),
      ],
    ),
  );

  Widget _buildHeader(ColorScheme colorScheme) => Column(
    children: [
      HugeIcon(
        icon: HugeIcons.strokeRoundedLockPassword,
        size: 42,
        color: colorScheme.primary,
      ),
      const SizedBox(height: 10),
      Text(
        'login_page_forget_dialog_title'.tr(),
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 5),
      Text(
        _emailVerified
            ? 'login_page_forget_password_step_subtitle'.tr()
            : 'login_page_forget_email_step_subtitle'.tr(),
        textAlign: TextAlign.center,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    ],
  );

  Widget _buildSteps(ColorScheme colorScheme) => Row(
    children: [
      _stepBadge(
        colorScheme,
        index: 1,
        label: 'login_page_forget_step_email'.tr(),
        active: !_emailVerified,
        complete: _emailVerified,
      ),
      Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          color: _emailVerified
              ? colorScheme.primary
              : colorScheme.outlineVariant,
        ),
      ),
      _stepBadge(
        colorScheme,
        index: 2,
        label: 'login_page_forget_step_password'.tr(),
        active: _emailVerified,
        complete: false,
      ),
    ],
  );

  Widget _stepBadge(
    ColorScheme colorScheme, {
    required int index,
    required String label,
    required bool active,
    required bool complete,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active || complete
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: complete
            ? HugeIcon(
                icon: HugeIcons.strokeRoundedTick01,
                size: 18,
                color: colorScheme.onPrimary,
              )
            : Text(
                '$index',
                style: TextStyle(
                  color: active
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
      const SizedBox(width: 7),
      Text(
        label,
        style: TextStyle(
          color: active || complete
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    ],
  );

  Widget _buildEmailStep(ColorScheme colorScheme) => KeyedSubtree(
    key: const ValueKey('email-step'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'login_page_forget_email'.tr(),
            hintText: 'login_page_forget_email'.tr(),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedAt,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            prefixIconConstraints: const BoxConstraints.tightFor(
              width: 36,
              height: 16,
            ),
          ),
          inputFormatters: [LengthLimitingTextInputFormatter(100)],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _captchaCtrl,
                decoration: InputDecoration(
                  labelText: 'login_page_captcha'.tr(),
                  hintText: 'login_page_captcha'.tr(),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedShield01,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 16,
                  ),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(4),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildCaptcha(colorScheme),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _emailCodeCtrl,
                decoration: InputDecoration(
                  labelText: 'login_page_forget_email_code'.tr(),
                  hintText: 'login_page_forget_email_code'.tr(),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedMailOpen01,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 16,
                  ),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(6),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: _captchaHeight,
              child: FilledButton.tonal(
                onPressed: (_isSendingCode || _countdown > 0)
                    ? null
                    : _handleSendCode,
                child: _isSendingCode
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _countdown > 0
                            ? '${_countdown}s'
                            : 'login_page_forget_send_code'.tr(),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 46,
          child: FilledButton(
            onPressed: (_isVerifyingEmail || _isSendingCode)
                ? null
                : _handleVerifyEmail,
            child: _isVerifyingEmail
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('login_page_forget_verify_next'.tr()),
          ),
        ),
      ],
    ),
  );

  Widget _buildPasswordStep(ColorScheme colorScheme) => KeyedSubtree(
    key: const ValueKey('password-step'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _passwordField(
          controller: _newPasswordCtrl,
          obscure: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          label: 'login_page_forget_new_password'.tr(),
        ),
        const SizedBox(height: 12),
        _passwordField(
          controller: _confirmPasswordCtrl,
          obscure: _obscureConfirmPassword,
          onToggle: () => setState(
            () => _obscureConfirmPassword = !_obscureConfirmPassword,
          ),
          label: 'login_page_forget_confirm_password'.tr(),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 46,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _handleResetPassword,
            child: _isSubmitting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('login_page_forget_reset'.tr()),
          ),
        ),
      ],
    ),
  );

  Widget _passwordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String label,
  }) => TextField(
    controller: controller,
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: label,
      hintText: label,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedLock,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      prefixIconConstraints: const BoxConstraints.tightFor(
        width: 36,
        height: 16,
      ),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: HugeIcon(
          icon: obscure
              ? HugeIcons.strokeRoundedViewOff
              : HugeIcons.strokeRoundedView,
          size: 16,
        ),
      ),
    ),
    inputFormatters: [LengthLimitingTextInputFormatter(20)],
  );

  /// 图形验证码，固定高度与输入框一致
  Widget _buildCaptcha(ColorScheme colorScheme) {
    if (_captcha == null) {
      return SizedBox(
        width: 120,
        height: _captchaHeight,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isCaptchaHovering = true),
      onExit: (_) => setState(() => _isCaptchaHovering = false),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surfaceContainerHigh,
        child: InkWell(
          onTap: _loadCaptcha,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 120,
            height: _captchaHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  base64Decode(_captcha!.imgBase64),
                  fit: BoxFit.cover,
                ),
                if (_isCaptchaHovering)
                  Container(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedRefresh01,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadCaptcha() async {
    try {
      // getCaptchaProvider 是缓存型 provider，点击刷新前必须先失效，
      // 否则 read 到的是缓存的旧验证码
      ref.invalidate(getCaptchaProvider);
      final res = await ref.read(getCaptchaProvider.future);
      if (!mounted) return;
      setState(() {
        _captcha = _SimpleCaptchaData(uuid: res.uuid, imgBase64: res.imgBase64);
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage('login_page_forget_captcha_load_failed'.tr(), isError: true);
    }
  }

  Future<void> _handleSendCode() async {
    final email = _emailCtrl.text.trim();
    final captchaCode = _captchaCtrl.text.trim();
    final captcha = _captcha;

    if (Validators.email(email) != null) {
      _showMessage('validator_email_invalid'.tr(), isError: true);
      return;
    }
    if (captcha == null) {
      _showMessage('login_page_forget_captcha_load_failed'.tr(), isError: true);
      return;
    }
    if (captchaCode.isEmpty) {
      _showMessage('login_page_captcha_validator_notnull'.tr(), isError: true);
      return;
    }

    setState(() => _isSendingCode = true);
    try {
      final msg = await ref
          .read(authControllerProvider.notifier)
          .forgotPasswordSendCode(
            email: email,
            captchaCode: captchaCode,
            uuid: captcha.uuid,
          );
      _showMessage(msg);
      _captchaCtrl.clear();
      _startCountdown();
      await _loadCaptcha();
    } catch (e) {
      _showMessage(_parseError(e), isError: true);
      await _loadCaptcha();
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  Future<void> _handleVerifyEmail() async {
    final email = _emailCtrl.text.trim();
    final emailCode = _emailCodeCtrl.text.trim();

    if (Validators.email(email) != null) {
      _showMessage('validator_email_invalid'.tr(), isError: true);
      return;
    }
    if (emailCode.length != 6) {
      _showMessage('login_page_forget_email_code_required'.tr(), isError: true);
      return;
    }

    setState(() => _isVerifyingEmail = true);
    try {
      final token = await ref
          .read(authControllerProvider.notifier)
          .forgotPasswordVerifyCode(email: email, emailCode: emailCode);
      if (!mounted) return;
      setState(() => _resetToken = token);
    } catch (e) {
      _showMessage(_parseError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isVerifyingEmail = false);
    }
  }

  Future<void> _handleResetPassword() async {
    final email = _emailCtrl.text.trim();
    final resetToken = _resetToken;
    final newPassword = _newPasswordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (resetToken == null || resetToken.isEmpty) {
      _showMessage('login_page_forget_email_code_required'.tr(), isError: true);
      return;
    }
    if (newPassword.length < 5 || newPassword.length > 20) {
      _showMessage('login_page_forget_password_len'.tr(), isError: true);
      return;
    }
    if (newPassword != confirmPassword) {
      _showMessage('login_page_forget_password_mismatch'.tr(), isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final msg = await ref
          .read(authControllerProvider.notifier)
          .forgotPasswordReset(
            email: email,
            resetToken: resetToken,
            newPassword: newPassword,
            confirmPassword: confirmPassword,
          );

      if (!mounted) return;
      _showMessage(msg);
      Navigator.of(context).pop(email);
    } catch (e) {
      _showMessage(_parseError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 60);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown -= 1);
      }
    });
  }

  String _parseError(Object e) {
    final raw = e.toString().trim();
    if (raw.startsWith('Exception:')) {
      return raw.substring('Exception:'.length).trim();
    }
    return raw.isEmpty ? 'login_failed'.tr() : raw;
  }

  void _showMessage(String message, {bool isError = false}) {
    Toast.showToast(
      message,
      type: isError ? ToastType.error : ToastType.success,
      singleton: true,
    );
  }
}

/// 图形验证码数据
///
/// 保存验证码的唯一标识符和 Base64 编码的图片数据。
class _SimpleCaptchaData {
  const _SimpleCaptchaData({required this.uuid, required this.imgBase64});

  /// 验证码唯一标识
  final String uuid;

  /// Base64 编码的验证码图片
  final String imgBase64;
}

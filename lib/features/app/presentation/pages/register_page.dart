// 注册页面，提供两步注册流程：邮箱验证和账号信息填写。
//
// 第一步验证邮箱并获取验证码，第二步填写用户名和密码完成注册。
import 'dart:async';
import 'package:hugeicons/hugeicons.dart';
import 'dart:convert';

import 'package:anoxia/common/utils/validators.dart';
import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, LengthLimitingTextInputFormatter, TextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 注册页面
///
/// 使用 Riverpod 管理状态，支持两步注册流程：先通过图形验证码获取邮箱验证码并验证邮箱，
/// 再填写用户名和密码完成注册。支持响应式布局，适配移动端和桌面端。
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

/// 注册页面状态
///
/// 管理两步注册流程的状态：邮箱验证码发送、邮箱验证、账号信息填写和提交。
/// 包含邮箱是否已验证的切换，以及密码可见性控制。
class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _emailCodeCtrl = TextEditingController();
  final _captchaCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  Timer? _countdownTimer;
  String? _emailVerificationToken;
  int _countdown = 0;
  bool _isSendingCode = false;
  bool _isVerifyingEmail = false;
  bool _isSubmitting = false;
  bool _emailCodeSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _emailVerified => _emailVerificationToken != null;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailCtrl.dispose();
    _emailCodeCtrl.dispose();
    _captchaCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 20 : 32,
                    16,
                    isMobile ? 20 : 32,
                    24 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 40)
                          .clamp(0.0, double.infinity)
                          .toDouble(),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(context, scheme),
                            const SizedBox(height: 22),
                            _buildSteps(scheme),
                            const SizedBox(height: 24),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: _emailVerified
                                  ? _buildAccountStep(scheme)
                                  : _buildEmailStep(scheme, isMobile),
                            ),
                          ],
                        ),
                      ),
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
              _resetEmailVerification();
            } else {
              Navigator.of(context).pop();
            }
          },
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
        ),
      ],
    ),
  );

  Widget _buildHeader(BuildContext context, ColorScheme scheme) => Column(
    children: [
      HugeIcon(icon: HugeIcons.strokeRoundedUserAdd01, size: 42, color: scheme.primary),
      const SizedBox(height: 10),
      Text(
        'register_title'.tr(),
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 5),
      Text(
        _emailVerified
            ? 'register_account_step_subtitle'.tr()
            : 'register_email_step_subtitle'.tr(),
        textAlign: TextAlign.center,
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
    ],
  );

  Widget _buildSteps(ColorScheme scheme) => Row(
    children: [
      _stepBadge(
        scheme,
        index: 1,
        label: 'register_step_email'.tr(),
        active: !_emailVerified,
        complete: _emailVerified,
      ),
      Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          color: _emailVerified ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      _stepBadge(
        scheme,
        index: 2,
        label: 'register_step_account'.tr(),
        active: _emailVerified,
        complete: false,
      ),
    ],
  );

  Widget _stepBadge(
    ColorScheme scheme, {
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
              ? scheme.primary
              : scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: complete
            ? HugeIcon(icon: HugeIcons.strokeRoundedTick01, size: 18, color: scheme.onPrimary)
            : Text(
                '$index',
                style: TextStyle(
                  color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
      const SizedBox(width: 7),
      Text(
        label,
        style: TextStyle(
          color: active || complete
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    ],
  );

  Widget _buildEmailStep(ColorScheme scheme, bool isMobile) => KeyedSubtree(
    key: const ValueKey('email-step'),
    child: Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            controller: _emailCtrl,
            hint: 'register_email'.tr(),
            icon: HugeIcons.strokeRoundedAt,
            maxLength: 50,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
            onChanged: _emailCodeSent ? _onEmailChanged : null,
          ),
          const SizedBox(height: 14),
          if (!_emailCodeSent || _countdown <= 0) ...[
            _captchaRow(scheme, isMobile),
            const SizedBox(height: 14),
          ],
          _emailCodeRow(isMobile),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _isVerifyingEmail ? null : _verifyEmail,
              icon: _isVerifyingEmail
                  ? const SizedBox.square(
                      dimension: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkBadge01),
              label: Text('register_verify_and_continue'.tr()),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _emailCodeRow(bool isMobile) {
    final field = _field(
      controller: _emailCodeCtrl,
      hint: 'register_email_code'.tr(),
      icon: HugeIcons.strokeRoundedMailOpen01,
      maxLength: 6,
      keyboardType: TextInputType.text,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
      ],
      validator: (value) => RegExp(r'^[a-zA-Z0-9]{6}$').hasMatch(value ?? '')
          ? null
          : 'register_email_code_invalid'.tr(),
    );
    final button = OutlinedButton(
      onPressed: _isSendingCode || _countdown > 0 ? null : _sendEmailCode,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
      ),
      child: _isSendingCode
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              _countdown > 0 ? '${_countdown}s' : 'register_send_code'.tr(),
            ),
    );
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [field, const SizedBox(height: 10), button],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: field),
        const SizedBox(width: 10),
        button,
      ],
    );
  }

  Widget _buildAccountStep(ColorScheme scheme) => Form(
    key: _accountFormKey,
    child: Column(
      key: const ValueKey('account-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkBadge01, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _emailCtrl.text.trim(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: _resetEmailVerification,
                child: Text('register_change_email'.tr()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _field(
          controller: _usernameCtrl,
          hint: 'register_username'.tr(),
          icon: HugeIcons.strokeRoundedUser,
          maxLength: 30,
          autofillHints: const [AutofillHints.newUsername],
          validator: (value) {
            final text = value?.trim() ?? '';
            return RegExp(r'^[a-zA-Z_]\w{1,29}$').hasMatch(text)
                ? null
                : 'register_username_invalid'.tr();
          },
        ),
        const SizedBox(height: 14),
        _passwordField(
          controller: _passwordCtrl,
          hint: 'register_password'.tr(),
          obscure: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 14),
        _passwordField(
          controller: _confirmPasswordCtrl,
          hint: 'register_confirm_password'.tr(),
          obscure: _obscureConfirmPassword,
          onToggle: () => setState(
            () => _obscureConfirmPassword = !_obscureConfirmPassword,
          ),
          validator: (value) => value == _passwordCtrl.text
              ? null
              : 'register_password_mismatch'.tr(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox.square(
                    dimension: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text('register_submit'.tr()),
          ),
        ),
      ],
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required List<List<dynamic>> icon,
    int? maxLength,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    autofillHints: autofillHints,
    onChanged: onChanged,
    inputFormatters: [
      if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ...?inputFormatters,
    ],
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: HugeIcon(icon: icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    validator: validator,
  );

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    obscureText: obscure,
    maxLength: 20,
    buildCounter:
        (_, {required currentLength, required isFocused, maxLength}) => null,
    autofillHints: const [AutofillHints.newPassword],
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedLock),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: HugeIcon(
          icon: obscure ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedView,
        ),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    validator:
        validator ??
        (value) {
          final length = value?.length ?? 0;
          return length < 5 || length > 20
              ? 'register_password_invalid'.tr()
              : null;
        },
  );

Widget _captchaRow(ColorScheme scheme, bool isMobile) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: _field(
          controller: _captchaCtrl,
          hint: 'login_page_captcha'.tr(),
          icon: HugeIcons.strokeRoundedShield01,
          maxLength: 4,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          ],
        ),
      ),
      SizedBox(width: isMobile ? 8 : 10),
      ref
          .watch(getCaptchaProvider)
          .when(
            data: (captcha) => InkWell(
              onTap: _refreshCaptcha,
              borderRadius: BorderRadius.circular(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: isMobile ? 104 : 120,
                  child: Image.memory(
                    base64Decode(captcha.imgBase64),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            loading: () => _captchaPlaceholder(
              const CircularProgressIndicator(strokeWidth: 2),
              scheme,
              isMobile,
            ),
            error: (_, _) => _captchaPlaceholder(
              IconButton(
                onPressed: _refreshCaptcha,
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh01),
              ),
              scheme,
              isMobile,
            ),
          ),
    ],
  );

  Widget _captchaPlaceholder(Widget child, ColorScheme scheme, bool isMobile) =>
      SizedBox(
        width: isMobile ? 104 : 120,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      );

  void _refreshCaptcha() {
    _captchaCtrl.clear();
    ref.invalidate(getCaptchaProvider);
  }

  Future<void> _sendEmailCode() async {
    final email = _emailCtrl.text.trim();
    final captcha = ref.read(getCaptchaProvider).value;
    final emailError = Validators.email(email);
    if (emailError != null) {
      _showMessage(emailError, isError: true);
      return;
    }
    if (_captchaCtrl.text.trim().isEmpty || captcha == null) {
      _showMessage('login_page_captcha_validator_notnull'.tr(), isError: true);
      if (captcha == null) _refreshCaptcha();
      return;
    }

    setState(() => _isSendingCode = true);
    try {
      final message = await ref
          .read(authControllerProvider.notifier)
          .sendRegisterEmailCode(
            email: email,
            captchaCode: _captchaCtrl.text.trim(),
            uuid: captcha.uuid,
          );
      if (!mounted) return;
      _showMessage(message);
      setState(() => _emailCodeSent = true);
      _startCountdown();
      _refreshCaptcha();
    } catch (error) {
      if (mounted) _showMessage(_errorText(error), isError: true);
      _refreshCaptcha();
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  Future<void> _verifyEmail() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;
    setState(() => _isVerifyingEmail = true);
    try {
      final token = await ref
          .read(authControllerProvider.notifier)
          .verifyRegisterEmailCode(
            email: _emailCtrl.text.trim(),
            emailCode: _emailCodeCtrl.text.trim(),
          );
      if (!mounted) return;
      setState(() => _emailVerificationToken = token);
    } catch (error) {
      if (mounted) _showMessage(_errorText(error), isError: true);
    } finally {
      if (mounted) setState(() => _isVerifyingEmail = false);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _countdown--);
      if (_countdown <= 0) timer.cancel();
    });
  }

  void _onEmailChanged(String _) {
    _countdownTimer?.cancel();
    _emailCodeCtrl.clear();
    setState(() {
      _countdown = 0;
      _emailCodeSent = false;
    });
    _refreshCaptcha();
  }

  void _resetEmailVerification() {
    _emailVerificationToken = null;
    _emailCodeSent = false;
    _emailCodeCtrl.clear();
    _usernameCtrl.clear();
    _passwordCtrl.clear();
    _confirmPasswordCtrl.clear();
    _refreshCaptcha();
    setState(() {});
  }

  Future<void> _submit() async {
    if (!(_accountFormKey.currentState?.validate() ?? false)) return;
    final token = _emailVerificationToken;
    if (token == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            username: _usernameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            emailVerificationToken: token,
            password: _passwordCtrl.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(_usernameCtrl.text.trim());
    } catch (error) {
      if (!mounted) return;
      final message = _errorText(error);
      _showMessage(message, isError: true);
      if (message.contains('验证')) _resetEmailVerification();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _errorText(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }
}

/// 忘记密码页面，提供用户名验证、图形验证码、邮箱验证码及密码重置功能。
///
/// 用户通过输入用户名、图形验证码获取邮箱验证码，然后输入新密码完成密码重置。
import 'dart:async';
import 'dart:convert';

import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 忘记密码页面
///
/// 使用 Riverpod 管理状态，支持图形验证码刷新、邮箱验证码发送倒计时、
/// 密码重置提交等完整流程。
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

/// 忘记密码页面状态
///
/// 管理用户名、验证码、邮箱验证码、新密码等输入框的控制器，以及提交状态和倒计时逻辑。
class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _usernameCtrl = TextEditingController();
  final _captchaCtrl = TextEditingController();
  final _emailCodeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _submitting = false;
  bool _sendingCode = false;
  int _countdown = 0;
  Timer? _countdownTimer;
  _SimpleCaptchaData? _captcha;

  @override
  void initState() {
    super.initState();
    _loadCaptcha();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _usernameCtrl.dispose();
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          Expanded(
                            child: Text(
                              'login_page_forget_dialog_title'.tr(),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameCtrl,
                        decoration: InputDecoration(
                          labelText: 'login_page_name'.tr(),
                          hintText: 'login_page_name'.tr(),
                        ),
                        inputFormatters: [LengthLimitingTextInputFormatter(30)],
                      ),
                      const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _captchaCtrl,
                                decoration: InputDecoration(
                                  labelText: 'login_page_captcha'.tr(),
                                  hintText: 'login_page_captcha'.tr(),
                                ),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(4),
                                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildDialogCaptcha(colorScheme),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _emailCodeCtrl,
                                decoration: InputDecoration(
                                  labelText: 'login_page_forget_email_code'.tr(),
                                  hintText: 'login_page_forget_email_code'.tr(),
                                ),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(6),
                                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.tonal(
                              onPressed: (_sendingCode || _countdown > 0)
                                  ? null
                                  : _handleSendCode,
                              child: _sendingCode
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _countdown > 0
                                          ? '${_countdown}s'
                                          : 'login_page_forget_send_code'.tr(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newPasswordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'login_page_forget_new_password'.tr(),
                          hintText: 'login_page_forget_new_password'.tr(),
                        ),
                        inputFormatters: [LengthLimitingTextInputFormatter(20)],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'login_page_forget_confirm_password'.tr(),
                          hintText: 'login_page_forget_confirm_password'.tr(),
                        ),
                        inputFormatters: [LengthLimitingTextInputFormatter(20)],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 46,
                        child: FilledButton(
                          onPressed: _submitting ? null : _handleResetPassword,
                          child: _submitting
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogCaptcha(ColorScheme colorScheme) {
    if (_captcha == null) {
      return SizedBox(
        width: 120,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
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

    return Material(
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: _loadCaptcha,
        child: SizedBox(
          width: 120,
          child: Image.memory(
            base64Decode(_captcha!.imgBase64),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Future<void> _loadCaptcha() async {
    try {
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
    final username = _usernameCtrl.text.trim();
    final captchaCode = _captchaCtrl.text.trim();
    final captcha = _captcha;

    if (!_isValidUsername(username)) {
      _showMessage('login_page_username_validator_regex'.tr(), isError: true);
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

    setState(() => _sendingCode = true);
    try {
      final msg = await ref
          .read(authControllerProvider.notifier)
          .forgotPasswordSendCode(
            username: username,
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
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _handleResetPassword() async {
    final username = _usernameCtrl.text.trim();
    final emailCode = _emailCodeCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (!_isValidUsername(username)) {
      _showMessage('login_page_username_validator_regex'.tr(), isError: true);
      return;
    }
    if (emailCode.isEmpty) {
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

    setState(() => _submitting = true);
    try {
      final msg = await ref
          .read(authControllerProvider.notifier)
          .forgotPasswordReset(
            username: username,
            emailCode: emailCode,
            newPassword: newPassword,
            confirmPassword: confirmPassword,
          );

      if (!mounted) return;
      _showMessage(msg);
      Navigator.of(context).pop(username);
    } catch (e) {
      _showMessage(_parseError(e), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool _isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z_]\w{1,29}$').hasMatch(username);
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
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

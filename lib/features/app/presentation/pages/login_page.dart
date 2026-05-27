import 'dart:convert';

import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/core/app_initializer.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            child: Assets.images.appIconPng.image(fit: BoxFit.cover),
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
      inputFormatters: [LengthLimitingTextInputFormatter(20)],
      decoration: InputDecoration(
        hintText: 'login_page_name'.tr(),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        prefixIcon: Icon(
          Icons.person_outline_rounded,
          color: colorScheme.onSurfaceVariant,
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
        if (value == null || value.trim().isEmpty) {
          return 'login_page_username_validator_notnull'.tr();
        }
        if (!RegExp(r'^[a-zA-Z_]\w{1,19}$').hasMatch(value.trim())) {
          return 'login_page_username_validator_regex'.tr();
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
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: colorScheme.onSurfaceVariant,
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
            inputFormatters: [LengthLimitingTextInputFormatter(4)],
            decoration: InputDecoration(
              hintText: 'login_page_captcha'.tr(),
              prefixIcon: Icon(
                Icons.shield_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
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
          onPressed: () {},
          child: Text(
            'login_page_forget'.tr(),
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
        Text('·', style: TextStyle(color: colorScheme.outline)),
        TextButton(
          onPressed: () {},
          child: Text(
            'login_page_register'.tr(),
            style: TextStyle(color: colorScheme.primary, fontSize: 13),
          ),
        ),
      ],
    );
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
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 120,
                    height: 40,
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
            height: 40,
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
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: colorScheme.onErrorContainer,
              ),
              onPressed: () => ref.invalidate(getCaptchaProvider),
            ),
          ),
        );
  }
}

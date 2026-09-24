import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/framework/domain/saved_account.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/auth/saved_accounts_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 访问令牌失效后的独立快速登录页。采用平铺布局，不额外套卡片。
class QuickLoginPage extends ConsumerStatefulWidget {
  const QuickLoginPage({super.key});

  @override
  ConsumerState<QuickLoginPage> createState() => _QuickLoginPageState();
}

class _QuickLoginPageState extends ConsumerState<QuickLoginPage> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(savedAccountsServiceProvider).value ?? const [];
    final quickAccounts = accounts
        .where((item) => item.quickLoginCredential.isNotEmpty);
    final account = quickAccounts.firstOrNull;
    final theme = Theme.of(context);

    return AppScaffold(
      hideAppBarLogo: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: account == null
                  ? _empty(context)
                  : _content(context, theme, account),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    ThemeData theme,
    SavedAccount account,
  ) {
    final isGuest = account.userType == '02';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 42,
          backgroundImage:
              account.avatar.isEmpty ? null : NetworkImage(account.avatar),
          child: account.avatar.isEmpty
              ? Text(account.nickName.characters.firstOrNull ?? 'A')
              : null,
        ),
        const SizedBox(height: 20),
        Text(
          account.nickName.isEmpty ? account.userName : account.nickName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text('@${account.userName}', style: theme.textTheme.bodyMedium),
        if (isGuest) ...[
          const SizedBox(height: 12),
          Chip(label: Text('quick_login_guest_badge'.tr())),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: _loading ? null : () => _login(account),
            child: _loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('quick_login_continue'.tr()),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _loading ? null : () => context.go('/login?manual=1'),
          child: Text('quick_login_back'.tr()),
        ),
      ],
    );
  }

  Widget _empty(BuildContext context) => Column(
        children: [
          Text('quick_login_unavailable'.tr()),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/login?manual=1'),
            child: Text('quick_login_back'.tr()),
          ),
        ],
      );

  Future<void> _login(SavedAccount account) async {
    setState(() => _loading = true);
    final success = await ref
        .read(authControllerProvider.notifier)
        .quickLogin(account);
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) context.go('/');
  }
}

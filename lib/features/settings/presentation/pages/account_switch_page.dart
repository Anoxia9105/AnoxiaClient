import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/dialogs/danger_confirm_dialog.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/app/presentation/pages/login_page.dart';
import 'package:anoxia/framework/domain/saved_account.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/auth/saved_accounts_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 切换账号页面
///
/// 展示登录成功过的账号列表（当前账号置顶高亮），点击其他账号一键切换；
/// 支持移除列表条目与「添加账号」（免登出叠加登录页，取消可返回本列表，
/// 原会话无缝保留）。
class AccountSwitchPage extends ConsumerWidget {
  const AccountSwitchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听登出：任意路径触发登出（添加账号的本地退出、侧边栏/抽屉退出、
    // token 过期等）都会使 auth 变为 AsyncData(null)，此时 go_router
    // 已重定向到登录页，但本页面若以弹窗/ push 路由形式展示则不会
    // 随重定向自动回收，需手动关闭避免登录页上方残留弹窗。
    ref.listen(authControllerProvider, (previous, next) {
      final wasLoggedIn = previous?.value != null;
      final isLoggedOut = next is AsyncData && next.value == null;
      if (wasLoggedIn && isLoggedOut && context.mounted) {
        // 延迟到下一帧再 pop，确保 go_router 的 redirect 已完成，
        // 且避免与 _addAccount / _switchTo 中的显式 pop 冲突时
        // 在同一帧内重复 pop。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      }
    });

    final colorScheme = Theme.of(context).colorScheme;
    final accountsAsync = ref.watch(savedAccountsServiceProvider);
    final currentUser = ref.watch(authControllerProvider).value;
    final isSwitching = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        centerTitle: DeviceUtil.isMobile(context),
        title: Text('account_switch_title'.tr()),
      ),
      body: accountsAsync.when(
        loading: () => const _AccountListSkeleton(),
        error: (e, _) => Center(child: Text('chat_load_failed'.tr())),
        data: (accounts) {
          // 当前登录账号排最前（可能尚未写入列表，如升级前登录的老会话）
          final sorted = [...accounts];
          if (currentUser != null) {
            sorted.removeWhere((a) => a.userId == currentUser.userId);
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  children: [
                    if (currentUser != null)
                      _CurrentUserTile(
                        nickName: currentUser.nickName,
                        userName: currentUser.userName,
                        avatar: currentUser.avatar,
                      ),
                    for (final account in sorted) ...[
                      const SizedBox(height: 10),
                      _SavedAccountTile(
                        account: account,
                        enabled: !isSwitching,
                        onTap: () => _switchTo(context, ref, account),
                        onRemove: () => _removeAccount(context, ref, account),
                      ),
                    ],
                    if (sorted.isEmpty && currentUser == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            'account_switch_empty'.tr(),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: .8),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusToken.lg),
                    ),
                  ),
                  onPressed: isSwitching ? null : () => _addAccount(context, ref),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedUserAdd01,
                    size: 18,
                  ),
                  label: Text('account_switch_add'.tr()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 一键切换到目标账号
  ///
  /// 成功后关闭本页回到新会话首页；目标凭据过期需密码时叠加可返回的
  /// 登录页（原会话无缝保留，取消即回本列表）；网络异常 toast 后停留本页。
  Future<void> _switchTo(
    BuildContext context,
    WidgetRef ref,
    SavedAccount account,
  ) async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .switchAccount(account);
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    // 失败分两种：需要密码（controller 已写预填且原会话已恢复）则叠加登录页，
    // 可返回本列表；纯网络失败无预填，停留本页（controller 已 toast）。
    final prefill = ref.read(loginPrefillAccountProvider);
    final current = ref.read(authControllerProvider).value;
    if (prefill == null || prefill.isEmpty || current == null) return;
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            LoginPage(isAddMode: true, initialUsername: account.userName),
      ),
    );
    // 叠加登录成功：新会话已就绪，关闭本列表回到首页；取消则停留本列表。
    if (added == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// 移除列表中的账号条目（不影响该账号的线上会话）
  Future<void> _removeAccount(
    BuildContext context,
    WidgetRef ref,
    SavedAccount account,
  ) async {
    final confirmed = await showDangerConfirmDialog(
      context,
      icon: HugeIcons.strokeRoundedDelete02,
      title: 'account_switch_remove'.tr(),
      content: 'account_switch_remove_confirm'.tr(
        args: [account.nickName.isEmpty ? account.userName : account.nickName],
      ),
      confirmLabel: 'account_switch_remove_confirm_label'.tr(),
    );
    if (!confirmed) return;
    await ref.read(savedAccountsServiceProvider.notifier).remove(account.userId);
    if (context.mounted) {
      Toast.showToast('account_switch_removed'.tr(), type: ToastType.success);
    }
  }

  /// 添加新账号：免登出叠加登录页（原会话无缝保留）
  ///
  /// 不调 logout、不清缓存：登录页以 `isAddMode` 命令式推上来，取消即回
  /// 本列表；新账号登录成功回值 true 后再关闭本列表回到新会话首页。
  /// 后端同账号多 token 并存，保留原 token 即可随时一键切回。
  Future<void> _addAccount(BuildContext context, WidgetRef ref) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const LoginPage(isAddMode: true),
      ),
    );
    // 成功才关列表回首页；取消则停留本列表，原会话零损耗。
    if (added == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// 当前登录账号条目（高亮、不可点）
class _CurrentUserTile extends StatelessWidget {
  const _CurrentUserTile({
    required this.nickName,
    required this.userName,
    required this.avatar,
  });

  final String nickName;
  final String userName;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: .35),
        ),
      ),
      child: Row(
        children: [
          AvatarWidget(url: avatar, name: nickName, size: 44, borderRadius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickName.isEmpty ? userName : nickName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@$userName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(RadiusToken.pill),
            ),
            child: Text(
              'account_switch_current'.tr(),
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 已保存账号条目：点击一键切换，尾部按钮移除
class _SavedAccountTile extends StatelessWidget {
  const _SavedAccountTile({
    required this.account,
    required this.enabled,
    required this.onTap,
    required this.onRemove,
  });

  final SavedAccount account;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(RadiusToken.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              AvatarWidget(
                url: account.avatar,
                name: account.nickName,
                size: 44,
                borderRadius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.nickName.isEmpty
                          ? account.userName
                          : account.nickName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${account.userName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'account_switch_remove'.tr(),
                visualDensity: VisualDensity.compact,
                onPressed: enabled ? onRemove : null,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCancelCircle,
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: .7),
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
                color: colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 账号列表骨架屏
///
/// 模拟真实布局：当前账号高亮卡 + 若干账号条目（头像 + 昵称/用户名 + 尾部图标）。
class _AccountListSkeleton extends StatelessWidget {
  const _AccountListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            children: [
              const _AccountTileSkeleton(highlight: true),
              for (var i = 0; i < 3; i++) ...[
                const SizedBox(height: 10),
                const _AccountTileSkeleton(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 单个账号条目骨架
class _AccountTileSkeleton extends StatelessWidget {
  final bool highlight;

  const _AccountTileSkeleton({this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        border: highlight
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: .35),
              )
            : null,
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 44, height: 44, circle: true),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 110, height: 14),
                SizedBox(height: 5),
                SkeletonLine(width: 76, height: 11),
              ],
            ),
          ),
          SkeletonBox(width: 20, height: 20, radius: 6, margin: EdgeInsets.only(left: 8)),
        ],
      ),
    );
  }
}

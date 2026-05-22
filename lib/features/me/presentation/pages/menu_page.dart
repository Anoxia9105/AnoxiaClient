import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/features/settings/presentation/pages/settings_page.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 抽屉左侧菜单页面（带完整个人信息展示）
class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final authAsync = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 顶部用户核心头像与账号名
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 16, 16),
              child: authAsync.when(
                loading: () => const SizedBox(
                  height: 64,
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (_, __) => const SizedBox(),
                data: (user) {
                  if (user == null) return const SizedBox();
                  return Row(
                    children: [
                      AvatarWidget(
                        url: user.avatar,
                        name: user.nickName,
                        size: 60,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.nickName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${user.userName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // 2. 个人详细资料展示面板（把 mypage 里的信息揉进抽屉）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: authAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (user) {
                  if (user == null) return const SizedBox();
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.wc_outlined,
                          value: _parseGender(user.sex),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: Icons.email_outlined,
                          value: user.email.isNotEmpty ? user.email : '--',
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          value: user.phoneNumber.isNotEmpty
                              ? user.phoneNumber
                              : '--',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(
                color: Colors.white.withValues(alpha: 0.12),
                height: 1,
              ),
            ),
            const SizedBox(height: 12),

            // 3. 核心功能菜单项
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildMenuTile(
                    context,
                    icon: HugeIcons.strokeRoundedUser,
                    title: 'me_page_title'.tr(), // 资料修改/详情入口
                    onTap: () {
                      // 开发意图：点击后跳转至对应的详情页修改
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildMenuTile(
                    context,
                    icon: HugeIcons.strokeRoundedLock,
                    title: 'me_password_submit'.tr(), // 密码修改
                    onTap: () {
                      // 开发意图：点击激活密码表单
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildMenuTile(
                    context,
                    icon: HugeIcons.strokeRoundedSettings01,
                    title: 'sidebar_setting'.tr(), // 设置页面
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 4. 底部退出登录
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
              // child: _buildMenuTile(
              //   context,
              //   icon: Icons.logout_rounded,
              //   title: 'logout'.tr(),
              //   isDanger: true,
              //   onTap: () => _showLogoutConfirmDialog(context, ref),
              // ),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: colorScheme.errorContainer.withValues(
                    alpha: 0.2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: Text('sidebar_logout'.tr()),
                onPressed: () => _showLogoutConfirmDialog(context, ref),
                icon: const Icon(Icons.logout_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 封装行内信息展示条（左图标 + 标签，右半透白数据）
  Widget _buildInfoRow({required IconData icon, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  /// 转换性别码到对应的语言 Key 文本
  String _parseGender(String sex) {
    switch (sex) {
      case '0':
        return 'contact_male'.tr();
      case '1':
        return 'contact_female'.tr();
      default:
        return 'contact_unknown_gender'.tr();
    }
  }

  /// 菜单磁贴组件
  Widget _buildMenuTile(
    BuildContext context, {
    required dynamic icon,
    required String title,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final displayColor = isDanger
        ? Theme.of(context).colorScheme.onErrorContainer
        : Colors.white;

    return ListTile(
      horizontalTitleGap: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: HugeIcon(
        icon: icon,
        color: displayColor.withValues(alpha: 0.85),
        size: 21,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: displayColor,
          fontSize: 14.5,
          fontWeight: isDanger ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }

  /// 登出二次确认弹窗
  void _showLogoutConfirmDialog(BuildContext context, WidgetRef ref) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text('logout'.tr()),
        content: Text('logout_confirm_hint'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'cancel'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authControllerProvider.notifier).logout();
            },
            child: Text(
              'confirm'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

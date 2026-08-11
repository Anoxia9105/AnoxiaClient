import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/dialogs/logout_confirm_dialog.dart';
import 'package:anoxia/features/settings/presentation/pages/settings_page.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'change_password_page.dart';
import 'me_page.dart';
import 'personal_qr_page.dart';

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
                error: (_, _) => const SizedBox(),
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
                error: (_, _) => const SizedBox(),
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
                          icon: HugeIcons.strokeRoundedToilet01,
                          value: _parseGender(user.sex),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: HugeIcons.strokeRoundedMail01,
                          value: user.email.isNotEmpty ? user.email : '--',
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: HugeIcons.strokeRoundedCall,
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // 第一组：个人中心 / 我的二维码 / 修改密码 / 深色模式
                  Material(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      children: [
                        _buildMenuTile(
                          context,
                          icon: HugeIcons.strokeRoundedUser,
                          title: 'me_page_title'.tr(), // 个人中心
                          onTap: () => _pushPage(context, const MyPage()),
                        ),
                        _buildTileDivider(),
                        _buildMenuTile(
                          context,
                          icon: HugeIcons.strokeRoundedQrCode01,
                          title: 'me_my_qr'.tr(), // 我的二维码
                          onTap: () {
                            final user = ref.read(authControllerProvider).value;
                            if (user != null) {
                              _pushPage(context, PersonalQrPage(user: user));
                            }
                          },
                        ),
                        _buildTileDivider(),
                        _buildMenuTile(
                          context,
                          icon: HugeIcons.strokeRoundedLock,
                          title: 'me_password_submit'.tr(), // 修改密码
                          onTap: () =>
                              _pushPage(context, const ChangePasswordPage()),
                        ),
                        _buildTileDivider(),
                        _buildDarkModeTile(ref),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 第二组：设置
                  Material(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      children: [
                        _buildMenuTile(
                          context,
                          icon: HugeIcons.strokeRoundedSettings01,
                          title: 'sidebar_setting'.tr(), // 设置页面
                          onTap: () =>
                              _pushPage(context, const SettingsPage()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 4. 底部退出登录
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
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
                onPressed: () async {
                  final shouldLogout = await showLogoutConfirmDialog(context);
                  if (shouldLogout && context.mounted) {
                    await ref.read(authControllerProvider.notifier).logout();
                  }
                },
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedLogout01),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 封装行内信息展示条（左图标 + 标签，右半透白数据）
  Widget _buildInfoRow({
    required List<List<dynamic>> icon,
    required String value,
  }) {
    return Row(
      children: [
        HugeIcon(icon: icon, size: 16, color: Colors.white.withValues(alpha: 0.6)),
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
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      minVerticalPadding: 14,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
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
      trailing: HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        size: 20,
        color: displayColor.withValues(alpha: 0.65),
      ),
      onTap: onTap,
    );
  }

  Widget _buildTileDivider() {
    return Divider(
      height: 1,
      indent: 50,
      endIndent: 14,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }

  /// 推入新页面（抽屉菜单项统一跳转入口）
  void _pushPage(BuildContext context, Widget page) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  /// 深色模式快捷开关
  ///
  /// 与设置页行为一致：切换亮度并同步兼容主题索引（保留强调色）。
  Widget _buildDarkModeTile(WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == Brightness.dark;
    return SwitchListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      minVerticalPadding: 14,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      secondary: HugeIcon(
        icon: isDark
            ? HugeIcons.strokeRoundedMoon02
            : HugeIcons.strokeRoundedSun03,
        color: Colors.white.withValues(alpha: 0.85),
        size: 21,
      ),
      title: Text(
        'sidebar_dark_mode'.tr(),
        style: const TextStyle(color: Colors.white, fontSize: 14.5),
      ),
      value: isDark,
      activeThumbColor: Colors.white,
      activeTrackColor: Colors.white.withValues(alpha: 0.45),
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
      onChanged: (_) => _toggleDarkMode(ref),
    );
  }

  /// 切换亮/暗模式
  void _toggleDarkMode(WidgetRef ref) {
    final next = ref.read(themeModeProvider) == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    ref.read(themeModeProvider.notifier).setMode(next);
    final accentIndex = ref.read(themeAccentProvider);
    ref.read(themeIndexProvider.notifier).setTheme(
      AppTheme.compatibilityThemeIndex(
        brightness: next,
        accentIndex: accentIndex,
      ),
    );
  }
}

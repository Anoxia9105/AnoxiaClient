import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 将项目中已有但原先分散在个人菜单里的账户能力集中到设置页。
class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({
    super.key,
    required this.onOpenProfile,
    required this.onOpenQrCode,
    required this.onChangePassword,
    required this.onSwitchAccount,
  });

  final VoidCallback onOpenProfile;
  final VoidCallback onOpenQrCode;
  final VoidCallback onChangePassword;

  /// 打开切换账号页面
  final VoidCallback onSwitchAccount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AccountTile(
          icon: HugeIcons.strokeRoundedUser,
          title: 'me_page_title'.tr(),
          subtitle: 'settings_account_profile_subtitle'.tr(),
          onTap: onOpenProfile,
        ),
        _divider(context),
        _AccountTile(
          icon: HugeIcons.strokeRoundedQrCode01,
          title: 'me_my_qr'.tr(),
          subtitle: 'settings_account_qr_subtitle'.tr(),
          onTap: onOpenQrCode,
        ),
        _divider(context),
        _AccountTile(
          icon: HugeIcons.strokeRoundedLock,
          title: 'me_password_title'.tr(),
          subtitle: 'settings_account_password_subtitle'.tr(),
          onTap: onChangePassword,
        ),
        _divider(context),
        _AccountTile(
          icon: HugeIcons.strokeRoundedUserArrowLeftRight,
          title: 'account_switch_title'.tr(),
          subtitle: 'settings_account_switch_subtitle'.tr(),
          onTap: onSwitchAccount,
        ),
      ],
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 52,
      endIndent: 8,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      minTileHeight: 64,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: HugeIcon(icon: icon, size: 20, color: colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        size: 18,
        color: colorScheme.outline,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}

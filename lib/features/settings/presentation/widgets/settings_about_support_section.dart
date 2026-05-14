import 'package:anoxia/common/widgets/VibratingBadge.dart';
import 'package:anoxia/features/settings/application/settings_page_controller.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'settings_item_card.dart';

class SettingsAboutSupportSection extends StatelessWidget {
  final String appVersionText;
  final bool hasAppUpdate;
  final SettingsPageState pageState;
  final VoidCallback onCheckUpdate;
  final ValueChanged<AppUpdateInfo> onNavigateToUpdatePage;
  final VoidCallback onOpenOpenSourceLicenses;

  const SettingsAboutSupportSection({
    super.key,
    required this.appVersionText,
    required this.hasAppUpdate,
    required this.pageState,
    required this.onCheckUpdate,
    required this.onNavigateToUpdatePage,
    required this.onOpenOpenSourceLicenses,
  });

  @override
  Widget build(BuildContext context) {
    final updateInfo = pageState.updateInfo;

    return SettingItemCard(
      title: 'settings_page_about_title'.tr(),
      subtitle: 'settings_page_about_subtitle'.tr(),
      icon: HugeIcons.strokeRoundedLink01,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 30),
        child: Column(
          children: [
            ListTile(
              dense: true,
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedQuillWrite01,
                size: 18,
              ),
              title: Text('settings_app_name'.tr()),
              trailing: const Text('Anoxia', style: TextStyle(fontSize: 14)),
            ),
            ListTile(
              dense: true,
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedSortByUp01,
                size: 18,
              ),
              title: Text('settings_app_version'.tr()),
              trailing: Text(
                appVersionText,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            ListTile(
              dense: true,
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedLicenseDraft,
                size: 18,
              ),
              title: const Text('开源许可'),
              trailing: const Icon(Icons.chevron_right_rounded, size: 18),
              onTap: onOpenOpenSourceLicenses,
            ),
            ListTile(
              dense: true,
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedCloudSavingDone01,
                size: 18,
              ),
              title: Row(
                children: [
                  Text('settings_update_check'.tr()),
                  if (hasAppUpdate) ...[
                    const SizedBox(width: 8),
                    const VibratingBadge(isDot: true),
                  ],
                ],
              ),
              subtitle: updateInfo?.latestVersion.isNotEmpty == true
                  ? Text(
                      '${'settings_update_latest'.tr()}: ${updateInfo!.latestVersion}',
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
              trailing: FilledButton.tonalIcon(
                onPressed: pageState.checkingUpdate ? null : onCheckUpdate,
                icon: pageState.checkingUpdate
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: Text('settings_update_check'.tr()),
              ),
            ),
            if (pageState.updateErrorKey != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Text(
                  pageState.updateErrorKey!.tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            if (updateInfo != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: .04)
                      : Colors.black.withValues(alpha: .03),
                  border: Border.all(
                    color: updateInfo.hasUpdate
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: .45)
                        : Theme.of(context).dividerColor.withValues(alpha: .25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      updateInfo.hasUpdate
                          ? '${'update_new_version'.tr()}: ${updateInfo.latestVersion}'
                          : 'settings_update_no_update'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: updateInfo.hasUpdate
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      updateInfo.releaseNotes.isNotEmpty
                          ? updateInfo.releaseNotes
                          : 'update_default_notes'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    if (updateInfo.hasUpdate &&
                        updateInfo.downloadUrl.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => onNavigateToUpdatePage(updateInfo),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text('update_now'.tr()),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

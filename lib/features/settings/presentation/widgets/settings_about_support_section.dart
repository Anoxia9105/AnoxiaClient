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
    final colorScheme = Theme.of(context).colorScheme;

    return SettingItemCard(
      title: 'settings_page_about_title'.tr(),
      subtitle: 'settings_page_about_subtitle'.tr(),
      icon: HugeIcons.strokeRoundedLink01,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anoxia IM Client',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${'settings_app_version'.tr()} $appVersionText',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onOpenOpenSourceLicenses,
                child: Text('settings_open_source_title'.tr()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: pageState.checkingUpdate ? null : onCheckUpdate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: hasAppUpdate
                        ? HugeIcons.strokeRoundedUpload03
                        : HugeIcons.strokeRoundedCloudSavingDone01,
                    size: 22,
                    color: hasAppUpdate
                        ? const Color(0xFFFF9800)
                        : colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _UpdateCopy(updateInfo: updateInfo)),
                  if (pageState.checkingUpdate)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
          if (pageState.updateErrorKey != null) ...[
            const SizedBox(height: 10),
            Text(
              pageState.updateErrorKey!.tr(),
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ],
          if (updateInfo?.hasUpdate == true &&
              updateInfo?.downloadUrl.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => onNavigateToUpdatePage(updateInfo!),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDownload01,
                  size: 18,
                ),
                label: Text('update_now'.tr()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpdateCopy extends StatelessWidget {
  final AppUpdateInfo? updateInfo;

  const _UpdateCopy({required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasUpdate = updateInfo?.hasUpdate == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                hasUpdate
                    ? '${'update_new_version'.tr()}: ${updateInfo!.latestVersion}'
                    : 'settings_update_check'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: hasUpdate
                      ? const Color(0xFFFF9800)
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (hasUpdate) ...[
              const SizedBox(width: 8),
              const VibratingBadge(isDot: true),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          updateInfo?.releaseNotes.isNotEmpty == true
              ? updateInfo!.releaseNotes
              : 'update_default_notes'.tr(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

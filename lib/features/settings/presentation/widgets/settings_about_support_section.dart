import 'package:anoxia/common/widgets/VibratingBadge.dart';
import 'package:anoxia/features/settings/application/settings_page_controller.dart';
import 'package:anoxia/framework/provider/setting/settings_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'settings_item_card.dart';

class SettingsAboutSupportSection extends StatefulWidget {
  final String appVersionText;
  final bool hasAppUpdate;
  final SettingsPageState pageState;
  final VoidCallback onCheckUpdate;
  final ValueChanged<AppUpdateInfo> onNavigateToUpdatePage;
  final VoidCallback onOpenOpenSourceLicenses;
  final VoidCallback onOpenDeveloperTribute;

  const SettingsAboutSupportSection({
    super.key,
    required this.appVersionText,
    required this.hasAppUpdate,
    required this.pageState,
    required this.onCheckUpdate,
    required this.onNavigateToUpdatePage,
    required this.onOpenOpenSourceLicenses,
    required this.onOpenDeveloperTribute,
  });

  @override
  State<SettingsAboutSupportSection> createState() =>
      _SettingsAboutSupportSectionState();
}

class _SettingsAboutSupportSectionState
    extends State<SettingsAboutSupportSection> {
  int _versionTapCount = 0;

  void _handleVersionTap() {
    _versionTapCount += 1;
    if (_versionTapCount < 7) return;
    _versionTapCount = 0;
    widget.onOpenDeveloperTribute();
  }

  @override
  Widget build(BuildContext context) {
    final updateInfo = widget.pageState.updateInfo;
    final colorScheme = Theme.of(context).colorScheme;

    return SettingItemCard(
      title: 'settings_page_about_title'.tr(),
      subtitle: 'settings_page_about_subtitle'.tr(),
      icon: HugeIcons.strokeRoundedLink01,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AppIntro(version: widget.appVersionText, onTap: _handleVersionTap),
          const SizedBox(height: 14),
          Text(
            'settings_about_description'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoPill(
                icon: HugeIcons.strokeRoundedMessageUser01,
                text: 'settings_about_im_focus'.tr(),
              ),
              _InfoPill(
                icon: HugeIcons.strokeRoundedShield01,
                text: 'settings_about_privacy'.tr(),
              ),
              _InfoPill(
                icon: HugeIcons.strokeRoundedRocket01,
                text: 'settings_about_one_person'.tr(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ActionRow(
            icon: HugeIcons.strokeRoundedGithub,
            title: 'settings_open_source_title'.tr(),
            subtitle: 'settings_about_open_source_subtitle'.tr(),
            onTap: widget.onOpenOpenSourceLicenses,
          ),
          const SizedBox(height: 12),
          _UpdateCard(
            updateInfo: updateInfo,
            checkingUpdate: widget.pageState.checkingUpdate,
            hasAppUpdate: widget.hasAppUpdate,
            onCheckUpdate: widget.onCheckUpdate,
          ),
          if (widget.pageState.updateErrorKey != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.pageState.updateErrorKey!.tr(),
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ],
          if (updateInfo?.hasUpdate == true &&
              updateInfo?.downloadUrl.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => widget.onNavigateToUpdatePage(updateInfo!),
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

class _AppIntro extends StatelessWidget {
  final String version;
  final VoidCallback onTap;

  const _AppIntro({required this.version, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              'A',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: Text(
                      '${'settings_app_version'.tr()} $version',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.underline,
                        decorationColor: colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 15, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            HugeIcon(icon: icon, size: 22, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  final AppUpdateInfo? updateInfo;
  final bool checkingUpdate;
  final bool hasAppUpdate;
  final VoidCallback onCheckUpdate;

  const _UpdateCard({
    required this.updateInfo,
    required this.checkingUpdate,
    required this.hasAppUpdate,
    required this.onCheckUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      mouseCursor: checkingUpdate
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onTap: checkingUpdate ? null : onCheckUpdate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
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
            if (checkingUpdate)
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

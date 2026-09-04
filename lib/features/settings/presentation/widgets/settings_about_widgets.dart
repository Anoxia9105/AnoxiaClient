import 'package:anoxia/framework/domain/app_update_info.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 分区标签组件
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

/// 应用概览卡片，集中展示品牌、版本、简介与产品特性。
class AppOverviewCard extends StatelessWidget {
  final String version;
  final VoidCallback onVersionTap;

  const AppOverviewCard({
    super.key,
    required this.version,
    required this.onVersionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('about-overview-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(RadiusToken.xl),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Assets.images.appLogo.image(
                  width: 52,
                  height: 52,
                  fit: BoxFit.contain,
                  isAntiAlias: true,
                  filterQuality: FilterQuality.high,
                  semanticLabel: 'Anoxia IM Client',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anoxia IM Client',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const Key('about-version-button'),
                          canRequestFocus: true,
                          borderRadius: BorderRadius.circular(RadiusToken.md),
                          onTap: onVersionTap,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Center(
                                child: Text(
                                  '${'settings_app_version'.tr()} $version',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: colorScheme.primary.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 16),
          Text(
            'settings_about_description'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoPill(
                icon: HugeIcons.strokeRoundedMessageUser01,
                text: 'settings_about_im_focus'.tr(),
              ),
              InfoPill(
                icon: HugeIcons.strokeRoundedShield01,
                text: 'settings_about_privacy'.tr(),
              ),
              InfoPill(
                icon: HugeIcons.strokeRoundedRocket01,
                text: 'settings_about_one_person'.tr(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 信息标签组件
class InfoPill extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String text;

  const InfoPill({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(RadiusToken.pill),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 15, color: colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              softWrap: true,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 操作行组件
class ActionGroup extends StatelessWidget {
  final List<ActionRow> children;

  const ActionGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index += 1) ...[
            children[index],
            if (index < children.length - 1)
              Divider(
                height: 1,
                indent: 62,
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
          ],
        ],
      ),
    );
  }
}

/// 强调支持类操作，在宽屏下可与同级操作并排显示。
class SupportShortcut extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SupportShortcut({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.secondaryContainer.withValues(alpha: 0.34),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        side: BorderSide(color: colorScheme.secondary.withValues(alpha: 0.18)),
      ),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconSurface(icon: icon, emphasized: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowUpRight01,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActionRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Row(
          children: [
            const SizedBox(width: 12),
            IconSurface(icon: icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
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
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

class IconSurface extends StatelessWidget {
  final List<List<dynamic>> icon;
  final bool emphasized;

  const IconSurface({super.key, required this.icon, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: emphasized
            ? colorScheme.secondaryContainer
            : colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(RadiusToken.lg),
      ),
      alignment: Alignment.center,
      child: HugeIcon(
        icon: icon,
        size: 20,
        color: emphasized
            ? colorScheme.onSecondaryContainer
            : colorScheme.primary,
      ),
    );
  }
}

/// 更新卡片组件
class UpdateCard extends StatelessWidget {
  final AppUpdateInfo? updateInfo;
  final bool checkingUpdate;
  final bool hasAppUpdate;
  final VoidCallback onCheckUpdate;

  const UpdateCard({
    super.key,
    required this.updateInfo,
    required this.checkingUpdate,
    required this.hasAppUpdate,
    required this.onCheckUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      enabled: !checkingUpdate,
      child: Material(
        color: hasAppUpdate
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.32)
            : colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusToken.xl),
          side: BorderSide(
            color: hasAppUpdate
                ? colorScheme.tertiary.withValues(alpha: 0.22)
                : colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        child: InkWell(
          mouseCursor: checkingUpdate
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onTap: checkingUpdate ? null : onCheckUpdate,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  IconSurface(
                    icon: hasAppUpdate
                        ? HugeIcons.strokeRoundedUpload03
                        : HugeIcons.strokeRoundedCloudSavingDone01,
                    emphasized: hasAppUpdate,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: UpdateCopy(updateInfo: updateInfo)),
                  if (checkingUpdate)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'settings_update_checking'.tr(),
                      ),
                    )
                  else
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 更新文案组件
class UpdateCopy extends StatelessWidget {
  final AppUpdateInfo? updateInfo;

  const UpdateCopy({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasUpdate = updateInfo?.hasUpdate == true;
    final statusColor = hasUpdate
        ? colorScheme.onTertiaryContainer
        : colorScheme.onSurface;

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
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (hasUpdate) ...[
              const SizedBox(width: 8),
              Semantics(
                label: 'update_new_version'.tr(),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
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

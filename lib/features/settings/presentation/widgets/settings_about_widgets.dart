import 'package:anoxia/framework/domain/app_update_info.dart';
import 'package:anoxia/framework/provider/setting/general_settings_provider.dart';
import 'package:anoxia/framework/provider/setting/update_download_provider.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';

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
                              padding: const EdgeInsets.symmetric(horizontal: SpacingToken.sm),
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
          const SizedBox(height: SpacingToken.lg),
          Divider(
            height: 1,
            color: colorScheme.primary.withValues(alpha: 0.12),
          ),
          const SizedBox(height: SpacingToken.lg),
          Text(
            'settings_about_description'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          const SizedBox(height: SpacingToken.lg),
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
            padding: const EdgeInsets.all(SpacingToken.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconSurface(icon: icon, emphasized: true),
                const SizedBox(width: SpacingToken.md),
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
                      const SizedBox(height: SpacingToken.xs),
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
                const SizedBox(width: SpacingToken.sm),
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
            const SizedBox(width: SpacingToken.md),
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
///
/// 状态机（按优先级）：
/// 1. 正在检查：转圈 + 检查中文案，点击禁用；
/// 2. 有新版本：标题版本号 + 小红点（+ 强制更新角标），副标题为更新说明，
///    下方追加静默下载状态行（下载中进度条 / 已就绪 / 失败重试 / 等待自动下载），
///    点击进入更新详情；
/// 3. 无更新：标题「检查更新」+ 副标题「已是最新」，点击重新检查。
class UpdateCard extends ConsumerWidget {
  final AppUpdateInfo? updateInfo;
  final bool checkingUpdate;
  final bool hasAppUpdate;
  final VoidCallback onCheckUpdate;
  final ValueChanged<AppUpdateInfo>? onOpenDetail;

  const UpdateCard({
    super.key,
    required this.updateInfo,
    required this.checkingUpdate,
    required this.hasAppUpdate,
    required this.onCheckUpdate,
    this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveHasUpdate =
        hasAppUpdate || updateInfo?.hasUpdate == true;
    final info = effectiveHasUpdate ? updateInfo : null;

    final VoidCallback? onTap;
    if (checkingUpdate) {
      onTap = null;
    } else if (info != null && onOpenDetail != null) {
      onTap = () => onOpenDetail!(info);
    } else {
      onTap = onCheckUpdate;
    }

    return Semantics(
      button: true,
      enabled: !checkingUpdate,
      label: effectiveHasUpdate
          ? 'update_new_version'.tr()
          : 'settings_update_check'.tr(),
      child: Material(
        color: effectiveHasUpdate
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.32)
            : colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusToken.xl),
          side: BorderSide(
            color: effectiveHasUpdate
                ? colorScheme.tertiary.withValues(alpha: 0.22)
                : colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        child: InkWell(
          mouseCursor: checkingUpdate || onTap == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: IconSurface(
                      icon: effectiveHasUpdate
                          ? HugeIcons.strokeRoundedUpload03
                          : HugeIcons.strokeRoundedCloudSavingDone01,
                      emphasized: effectiveHasUpdate,
                    ),
                  ),
                  const SizedBox(width: SpacingToken.md),
                  Expanded(
                    child: checkingUpdate
                        ? const _CheckingCopy()
                        : info != null
                            ? _HasUpdateCopy(updateInfo: info)
                            : const _NoUpdateCopy(),
                  ),
                  const SizedBox(width: SpacingToken.sm),
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
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: HugeIcon(
                        icon: info != null
                            ? HugeIcons.strokeRoundedArrowRight01
                            : HugeIcons.strokeRoundedRefresh01,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
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

/// 正在检查中的文案
class _CheckingCopy extends StatelessWidget {
  const _CheckingCopy();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings_update_checking'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: SpacingToken.xs),
        Text(
          'settings_update_checking_desc'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

/// 无更新时的文案：标题检查更新 + 副标题已是最新
class _NoUpdateCopy extends StatelessWidget {
  const _NoUpdateCopy();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings_update_check'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: SpacingToken.xs),
        Text(
          'settings_update_no_update'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

/// 有新版本时的文案：版本标题 + 更新说明 + 静默下载状态行
class _HasUpdateCopy extends ConsumerWidget {
  final AppUpdateInfo updateInfo;

  const _HasUpdateCopy({required this.updateInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = colorScheme.onTertiaryContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '${'update_new_version'.tr()}: ${updateInfo.latestVersion}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: SpacingToken.sm),
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
            if (updateInfo.forceUpdate) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(RadiusToken.pill),
                ),
                child: Text(
                  'update_force_badge'.tr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: SpacingToken.xs),
        Text(
          updateInfo.releaseNotes.isNotEmpty
              ? updateInfo.releaseNotes
              : 'update_default_notes'.tr(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: SpacingToken.sm),
        _DownloadStatusLine(updateInfo: updateInfo),
      ],
    );
  }
}

/// 静默下载状态行：下载中（进度条+百分比+大小）/ 已就绪 / 失败 / 等待自动下载
class _DownloadStatusLine extends ConsumerWidget {
  final AppUpdateInfo updateInfo;

  const _DownloadStatusLine({required this.updateInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final download = ref.watch(updateDownloadControllerProvider);
    final matchesVersion =
        download.version.isNotEmpty &&
        download.version == updateInfo.latestVersion;

    if (matchesVersion &&
        download.phase == UpdateDownloadPhase.downloading) {
      final percent = (download.progress * 100).clamp(0, 100).toInt();
      final sizeLabel = download.totalBytes > 0
          ? ' · ${_formatBytes(download.receivedBytes)} / ${_formatBytes(download.totalBytes)}'
          : '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: download.progress <= 0 ? null : download.progress,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${'update_downloading'.tr()} $percent%$sizeLabel',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(RadiusToken.pill),
            child: LinearProgressIndicator(
              value: download.progress <= 0 ? null : download.progress,
              minHeight: 5,
            ),
          ),
        ],
      );
    }

    if (matchesVersion && download.phase == UpdateDownloadPhase.ready) {
      return Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedTick01,
            size: 14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'update_ready_state'.tr(),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    if (matchesVersion && download.phase == UpdateDownloadPhase.failed) {
      final reason = download.errorMessage.isNotEmpty
          ? download.errorMessage.tr()
          : 'update_error_generic_safe'.tr();
      return Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlertCircle,
            size: 14,
            color: colorScheme.error,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$reason · ${'update_retry_download'.tr()}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    // 空闲态：按自动下载开关给出不同 hint，避免用户困惑为何没有进度。
    final autoDownload = ref.watch(autoDownloadUpdateProvider);
    return Row(
      children: [
        HugeIcon(
          icon: autoDownload
              ? HugeIcons.strokeRoundedCloudSavingDone01
              : HugeIcons.strokeRoundedInformationCircle,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            autoDownload
                ? 'settings_update_waiting_download'.tr()
                : 'settings_update_manual_hint'.tr(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// 字节数格式化：B / KB / MB，保留 1 位小数
String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(1)} MB';
}

/// 更新文案组件（保留旧入口，内部转调新状态文案，避免外部调用方编译失败）
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
              const SizedBox(width: SpacingToken.sm),
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
        const SizedBox(height: SpacingToken.xs),
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

import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 更新页品牌与版本直接平铺，配色沿用用户主题。
class UpdateHeroCard extends StatelessWidget {
  const UpdateHeroCard({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.isForceUpdate,
  });
  final String currentVersion;
  final String latestVersion;
  final bool isForceUpdate;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 650;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Assets.images.appLogo.image(
              key: const Key('update-flat-logo'),
              width: compact ? 64 : 80,
              height: compact ? 72 : 88,
              fit: BoxFit.contain,
              semanticLabel: 'Anoxia',
            ),
            const SizedBox(width: SpacingToken.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anoxia',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: SpacingToken.xs),
                  Text(
                    'update_new_version'.tr(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SpacingToken.sm),
                  Text(
                    'update_download_intro'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingToken.xl),
        Wrap(
          spacing: SpacingToken.md,
          runSpacing: SpacingToken.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (currentVersion.isNotEmpty)
              Text(
                '${'update_current_version'.tr()} $currentVersion',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 16),
            Text(latestVersion, style: theme.textTheme.titleSmall),
            if (isForceUpdate) const UpdateForceBadge(),
          ],
        ),
        const SizedBox(height: SpacingToken.lg),
        Divider(
          height: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: .5),
        ),
        if (isForceUpdate) ...[
          const SizedBox(height: SpacingToken.lg),
          const UpdateForceNotice(),
        ],
      ],
    );
  }
}

class UpdateForceBadge extends StatelessWidget {
  const UpdateForceBadge({super.key});
  @override
  Widget build(BuildContext context) => Text(
    'update_force_badge'.tr(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.error,
    ),
  );
}

class UpdateForceNotice extends StatelessWidget {
  const UpdateForceNotice({super.key});
  @override
  Widget build(BuildContext context) => Text(
    'update_force_notice'.tr(),
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      height: 1.7,
    ),
  );
}

class UpdateReleaseNotesCard extends StatelessWidget {
  const UpdateReleaseNotesCard({super.key, required this.notes});
  final List<String> notes;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('update_release_notes'.tr(), style: theme.textTheme.titleSmall),
        const SizedBox(height: SpacingToken.xl),
        for (var i = 0; i < notes.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: SpacingToken.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${i + 1}'.padLeft(2, '0'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    notes[i],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String formatUpdateBytes(int bytes) {
  if (bytes < 1024) return '${bytes.clamp(0, 1024)} B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

/// 每个阶段只有一个主要操作。下载中与暂停态共用同一任务。
class UpdateActionArea extends StatelessWidget {
  const UpdateActionArea({
    super.key,
    required this.isDownloading,
    required this.hasStarted,
    required this.openedInBrowser,
    required this.downloadFinished,
    required this.progress,
    required this.onStartDownload,
    this.isReady = false,
    this.isPaused = false,
    this.onInstall,
    this.onPause,
    this.onResume,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.installing = false,
  });
  final bool isDownloading;
  final bool isPaused;
  final bool hasStarted;
  final bool openedInBrowser;
  final bool downloadFinished;
  final bool isReady;
  final bool installing;
  final double progress;
  final int receivedBytes;
  final int totalBytes;
  final String? errorMessage;
  final VoidCallback onStartDownload;
  final VoidCallback? onInstall;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;
      final compact = box.maxWidth < 600;
      final active = isDownloading || isPaused;
      final showProgress =
          active || isReady || (errorMessage != null && receivedBytes > 0);
      final percentage = (progress.clamp(0.0, 1.0) * 100).toInt();
      final title = openedInBrowser
          ? 'update_opened_in_browser'.tr()
          : errorMessage != null
          ? errorMessage!
          : isReady
          ? 'update_ready_state'.tr()
          : isPaused
          ? 'update_paused'.tr()
          : isDownloading
          ? 'update_download_active'.tr()
          : 'update_download_available'.tr();
      final action = openedInBrowser
          ? onStartDownload
          : isReady
          ? onInstall
          : isPaused
          ? onResume
          : isDownloading
          ? onPause
          : onStartDownload;
      final label = openedInBrowser
          ? 'update_reopen_browser'
          : isReady
          ? 'update_install_now'
          : isPaused
          ? 'update_resume_download'
          : isDownloading
          ? 'update_pause_download'
          : errorMessage != null || hasStarted
          ? 'update_retry_download'
          : 'update_start_download';
      final icon = isDownloading
          ? HugeIcons.strokeRoundedPause
          : isReady
          ? HugeIcons.strokeRoundedTick01
          : HugeIcons.strokeRoundedDownload01;
      return Container(
        key: const Key('update-download-panel'),
        padding: EdgeInsets.symmetric(
          vertical: SpacingToken.xl,
          horizontal: compact && active ? 0 : SpacingToken.xl,
        ),
        decoration: BoxDecoration(
          color: compact && active
              ? Colors.transparent
              : cs.surfaceContainerLow,
          borderRadius: compact && active
              ? null
              : BorderRadius.circular(RadiusToken.lg),
          border: compact && active
              ? Border.symmetric(
                  horizontal: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: .5),
                  ),
                )
              : Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: errorMessage == null ? cs.onSurface : cs.error,
                      ),
                    ),
                  ),
                  if (showProgress) ...[
                    const SizedBox(width: SpacingToken.md),
                    Text(
                      '$percentage%',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: SpacingToken.lg),
            if (showProgress) ...[
              LinearProgressIndicator(
                key: const Key('update-download-progress'),
                value: isPaused || isReady || totalBytes > 0 || progress > 0
                    ? progress.clamp(0.0, 1.0)
                    : null,
                minHeight: 6,
                borderRadius: BorderRadius.circular(RadiusToken.pill),
                color: isPaused ? cs.onSurfaceVariant : cs.primary,
                semanticsLabel: 'update_downloading'.tr(),
                semanticsValue: '$percentage%',
              ),
              const SizedBox(height: SpacingToken.md),
            ],
            Text(
              showProgress
                  ? totalBytes > 0
                        ? '${formatUpdateBytes(receivedBytes)} / ${formatUpdateBytes(totalBytes)}'
                        : 'update_size_unknown'.tr(
                            args: [formatUpdateBytes(receivedBytes)],
                          )
                  : totalBytes > 0
                  ? 'update_package_size'.tr(
                      args: [formatUpdateBytes(totalBytes)],
                    )
                  : 'update_package_unknown'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            if (isReady) ...[
              const SizedBox(height: SpacingToken.md),
              Text(
                'update_install_integrity'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.7,
                ),
              ),
            ],
            const SizedBox(height: SpacingToken.xl),
            FilledButton.tonalIcon(
              key: const Key('update-primary-action'),
              onPressed: installing ? null : action,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: active
                    ? cs.primaryContainer.withValues(alpha: .45)
                    : cs.primary,
                foregroundColor: active ? cs.primary : cs.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingToken.lg,
                  vertical: SpacingToken.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusToken.md),
                ),
              ),
              icon: installing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : HugeIcon(icon: icon, size: 18),
              label: Text(label.tr(), textAlign: TextAlign.center),
            ),
          ],
        ),
      );
    },
  );
}

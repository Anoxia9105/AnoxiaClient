import 'package:anoxia/framework/provider/setting/update_download_provider.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 下载完成后的全局通知卡片；支持按钮关闭和上滑关闭。
class UpdateReadyBanner extends ConsumerWidget {
  const UpdateReadyBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateDownloadControllerProvider);
    if (state.phase != UpdateDownloadPhase.ready ||
        state.bannerDismissed ||
        state.filePath.isEmpty) {
      return const SizedBox.shrink();
    }
    final version = state.version.startsWith('v')
        ? state.version
        : 'v${state.version}';
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Dismissible(
              key: ValueKey('update-ready-${state.version}'),
              direction: DismissDirection.up,
              onDismissed: (_) => ref
                  .read(updateDownloadControllerProvider.notifier)
                  .dismissBanner(),
              child: UpdateReadyCard(
                version: version,
                onClose: () => ref
                    .read(updateDownloadControllerProvider.notifier)
                    .dismissBanner(),
                onInstall: () async {
                  final ok = await ref
                      .read(updateDownloadControllerProvider.notifier)
                      .installReadyUpdate();
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('update_error_open_installer'.tr()),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 文案、操作分行，避免日语及大字体把正文挤成单字列。
class UpdateReadyCard extends StatelessWidget {
  final String version;
  final VoidCallback onClose;
  final VoidCallback onInstall;
  const UpdateReadyCard({
    super.key,
    required this.version,
    required this.onClose,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      elevation: 6,
      shadowColor: cs.shadow.withValues(alpha: .16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, right: 10),
                  child: Icon(
                    Icons.system_update_alt_rounded,
                    color: cs.primary,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'update_ready_banner_title'.tr(args: [version]),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'common_close'.tr(),
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'update_ready_banner_subtitle'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onInstall,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text(
                'update_install_now'.tr(),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

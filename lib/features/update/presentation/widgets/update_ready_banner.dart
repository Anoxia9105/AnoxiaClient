import 'package:anoxia/framework/provider/setting/update_download_provider.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 全局「新版本已就绪」横幅
///
/// 后台静默下载完成后在主界面顶部弹出：提示用户可以直接安装，
/// 支持一键安装与手动关闭。桌面端与移动端统一交互。
///
/// 展示条件：下载状态为 ready 且用户未手动关闭。
/// 挂载点：app.dart 的 [_AppOverlays] 全局浮层（覆盖所有页面/路由）。
class UpdateReadyBanner extends ConsumerWidget {
  const UpdateReadyBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateDownloadControllerProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final shouldShow =
        state.phase == UpdateDownloadPhase.ready &&
        !state.bannerDismissed &&
        state.filePath.isNotEmpty;
    if (!shouldShow) return const SizedBox.shrink();

    final versionLabel = state.version.startsWith('v')
        ? state.version
        : 'v${state.version}';

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SpacingToken.lg,
              SpacingToken.sm,
              SpacingToken.lg,
              0,
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) {
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, -16 * (1 - t)),
                    child: child,
                  ),
                );
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingToken.lg,
                  vertical: SpacingToken.md,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(RadiusToken.lg),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: .6),
                  ),
                ),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedDownload04,
                      size: 20,
                      color: cs.primary,
                    ),
                    const SizedBox(width: SpacingToken.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'update_ready_banner_title'.tr(args: [versionLabel]),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: SpacingToken.xs),
                          Text(
                            'update_ready_banner_subtitle'.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: SpacingToken.sm),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(RadiusToken.pill),
                        ),
                      ),
                      onPressed: () async {
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
                      child: Text('update_install_now'.tr()),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'common_close'.tr(),
                      onPressed: () => ref
                          .read(updateDownloadControllerProvider.notifier)
                          .dismissBanner(),
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

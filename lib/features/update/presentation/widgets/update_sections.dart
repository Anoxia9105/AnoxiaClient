import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';
import 'package:anoxia/gen/assets.gen.dart';

/// 更新页面相关组件集合
///
/// 统一约定：
/// - 配色全部取自 [ColorScheme]，不写死颜色，保证与用户主题（16 套强调色 + 亮/暗）一致
/// - 圆角/间距全部取自 [RadiusToken] / [SpacingToken]
/// - 文案全部走 easy_localization

/// 更新页卡片通用装饰
BoxDecoration updateCardDecoration(ColorScheme cs) => BoxDecoration(
  color: cs.surfaceContainerLow,
  borderRadius: BorderRadius.circular(RadiusToken.xl),
  border: Border.all(color: cs.outlineVariant.withValues(alpha: .6)),
);

/// 版本号显示：已带 v 前缀时不再重复添加
String _versionLabel(String version) {
  final v = version.trim();
  if (v.isEmpty) return '-';
  return v.startsWith('v') ? v : 'v$v';
}

/// 更新头部卡片
///
/// 展示品牌 Logo、版本对比（当前 → 最新）以及强制更新提示
class UpdateHeroCard extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final bool isForceUpdate;

  const UpdateHeroCard({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.isForceUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        SpacingToken.xl,
        SpacingToken.xl,
        SpacingToken.xl,
        SpacingToken.lg,
      ),
      decoration: updateCardDecoration(cs),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(SpacingToken.md),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(RadiusToken.xl),
            ),
            child: Assets.images.appLogo.image(
              fit: BoxFit.contain,
              isAntiAlias: true,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: SpacingToken.lg),
          Text(
            'update_new_version'.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          if (isForceUpdate) ...[
            const SizedBox(height: SpacingToken.sm),
            const UpdateForceBadge(),
          ],
          const SizedBox(height: SpacingToken.sm),
          Text(
            (isForceUpdate ? 'update_hero_subtitle_force' : 'update_hero_subtitle')
                .tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: SpacingToken.xl),
          Row(
            children: [
              Expanded(
                child: _VersionPill(
                  label: 'update_current_version'.tr(),
                  version: currentVersion,
                  highlight: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingToken.md,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 18,
                  color: cs.outline,
                ),
              ),
              Expanded(
                child: _VersionPill(
                  label: 'update_latest_version'.tr(),
                  version: latestVersion,
                  highlight: true,
                ),
              ),
            ],
          ),
          if (isForceUpdate) ...[
            const SizedBox(height: SpacingToken.lg),
            const UpdateForceNotice(),
          ],
        ],
      ),
    );
  }
}

/// 强制更新标识（本地化，替代原先写死的 FORCE 角标）
class UpdateForceBadge extends StatelessWidget {
  const UpdateForceBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(RadiusToken.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            size: 13,
            color: cs.onErrorContainer,
          ),
          const SizedBox(width: 5),
          Text(
            'update_force_badge'.tr(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onErrorContainer,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
    );
  }
}

/// 强制更新说明条：明确告知不可跳过
class UpdateForceNotice extends StatelessWidget {
  const UpdateForceNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingToken.md),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              size: 18,
              color: cs.onErrorContainer,
            ),
          ),
          const SizedBox(width: SpacingToken.sm),
          Expanded(
            child: Text(
              'update_force_notice'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onErrorContainer,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 版本号展示块
class _VersionPill extends StatelessWidget {
  final String label;
  final String version;
  final bool highlight;

  const _VersionPill({
    required this.label,
    required this.version,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fg = highlight ? cs.onPrimaryContainer : cs.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: SpacingToken.md),
      decoration: BoxDecoration(
        color: highlight ? cs.primaryContainer : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: highlight
            ? null
            : Border.all(color: cs.outlineVariant.withValues(alpha: .6)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg.withValues(alpha: .72),
            ),
          ),
          const SizedBox(height: SpacingToken.xs),
          Text(
            _versionLabel(version),
            style: theme.textTheme.titleSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 更新日志卡片组件
///
/// 显示新版本的更新内容列表
class UpdateReleaseNotesCard extends StatelessWidget {
  final List<String> notes;

  const UpdateReleaseNotesCard({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingToken.xl),
      decoration: updateCardDecoration(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedFile01,
                size: 16,
                color: cs.primary,
              ),
              const SizedBox(width: SpacingToken.xs),
              Text(
                'update_release_notes'.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingToken.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(RadiusToken.pill),
                  color: cs.secondaryContainer,
                ),
                child: Text(
                  '${notes.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingToken.md),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: .6)),
          const SizedBox(height: SpacingToken.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: notes.map((line) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            line,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 更新操作区域组件
///
/// 三种状态：
/// - 下载中：展示进度条与百分比
/// - 移动端已跳转浏览器：提示用户到浏览器完成安装，可重新打开
/// - 默认：主按钮「立即升级」（失败重试时变为「重试下载」）
class UpdateActionArea extends StatelessWidget {
  final bool isDownloading;
  final bool hasStarted;
  final bool openedInBrowser;
  final double progress;
  final VoidCallback onStartDownload;

  const UpdateActionArea({
    super.key,
    required this.isDownloading,
    required this.hasStarted,
    required this.openedInBrowser,
    required this.progress,
    required this.onStartDownload,
  });

  String _downloadText() {
    if (progress >= 1) {
      return 'update_preparing_install'.tr();
    }
    return 'update_downloading'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (isDownloading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(SpacingToken.lg),
        decoration: updateCardDecoration(cs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: progress >= 1
                      ? HugeIcons.strokeRoundedSmartPhone01
                      : HugeIcons.strokeRoundedDownload04,
                  size: 18,
                  color: cs.primary,
                ),
                const SizedBox(width: SpacingToken.sm),
                Expanded(
                  child: Text(
                    _downloadText(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).clamp(0, 100).toInt()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingToken.sm),
            LinearProgressIndicator(
              value: progress <= 0 ? null : progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(RadiusToken.pill),
            ),
          ],
        ),
      );
    }

    // 移动端跳浏览器安装：不要回落成「重试下载」，避免用户以为下载失败
    if (openedInBrowser) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(SpacingToken.lg),
        decoration: updateCardDecoration(cs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedTick01,
                  size: 18,
                  color: cs.primary,
                ),
                const SizedBox(width: SpacingToken.sm),
                Expanded(
                  child: Text(
                    'update_opened_in_browser'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingToken.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onStartDownload,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDownload01,
                  size: 16,
                ),
                label: Text('update_reopen_browser'.tr()),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusToken.lg),
          ),
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: onStartDownload,
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedDownload01),
        label: Text(hasStarted ? 'update_retry_download'.tr() : 'update_now'.tr()),
      ),
    );
  }
}

/// 更新错误提示卡片组件
///
/// 显示更新过程中的错误信息
class UpdateErrorCard extends StatelessWidget {
  final String message;

  const UpdateErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingToken.md),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(color: cs.error.withValues(alpha: .30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              color: cs.onErrorContainer,
              size: 18,
            ),
          ),
          const SizedBox(width: SpacingToken.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onErrorContainer,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

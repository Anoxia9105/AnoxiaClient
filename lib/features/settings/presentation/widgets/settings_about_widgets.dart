import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 品牌标识直接平铺，PC 横排、手机居中，不叠加底板与阴影。
class AboutBrandHeader extends StatelessWidget {
  const AboutBrandHeader({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final compact = box.maxWidth < 600;
      final theme = Theme.of(context);
      final logo = Assets.images.appLogo.image(
        key: const Key('about-flat-logo'),
        width: compact ? 80 : 96,
        height: compact ? 88 : 104,
        fit: BoxFit.contain,
        semanticLabel: 'Anoxia',
      );
      final copy = Column(
        crossAxisAlignment: compact
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            'Anoxia',
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: compact ? 38 : 48,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: SpacingToken.sm),
          Text(
            'about_tagline'.tr(),
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: SpacingToken.xxl),
        child: compact
            ? Column(
                children: [
                  logo,
                  const SizedBox(height: SpacingToken.lg),
                  copy,
                ],
              )
            : Row(
                children: [
                  logo,
                  const SizedBox(width: SpacingToken.xxl),
                  Expanded(child: copy),
                ],
              ),
      );
    },
  );
}

class AboutAuthorNote extends StatelessWidget {
  const AboutAuthorNote({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingToken.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: SpacingToken.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'about_author_title'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingToken.sm),
                Text(
                  'about_author_note'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.9,
                  ),
                ),
                const SizedBox(height: SpacingToken.md),
                Align(
                  key: const Key('about-author-signature'),
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    'about_author_signature'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

/// 一行三个真实功能入口；窄屏只保留图标与标题，文字放大时自然增高。
class AboutQuickAction extends StatelessWidget {
  const AboutQuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.compact,
  });
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(RadiusToken.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        child: Padding(
          padding: EdgeInsets.all(compact ? SpacingToken.md : SpacingToken.lg),
          child: Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              HugeIcon(icon: icon, color: cs.primary, size: 23),
              const SizedBox(height: SpacingToken.md),
              Text(
                title,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: compact ? 12 : 14,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: SpacingToken.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AboutResourceRow extends StatelessWidget {
  const AboutResourceRow({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.copy = false,
  });
  final String title;
  final String? subtitle;
  final List<List<dynamic>>? icon;
  final VoidCallback onTap;
  final bool copy;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: .5)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: SpacingToken.md),
              child: Row(
                children: [
                  if (icon != null) ...[
                    HugeIcon(icon: icon!, size: 20, color: cs.onSurfaceVariant),
                    const SizedBox(width: SpacingToken.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.bodyMedium),
                        if (subtitle != null) ...[
                          const SizedBox(height: SpacingToken.xs),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: SpacingToken.sm),
                  HugeIcon(
                    icon: copy
                        ? HugeIcons.strokeRoundedCopy01
                        : HugeIcons.strokeRoundedArrowRight01,
                    size: 16,
                    color: cs.onSurfaceVariant,
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

class AboutVersionRow extends StatelessWidget {
  const AboutVersionRow({
    super.key,
    required this.version,
    required this.status,
    required this.checking,
    required this.hasUpdate,
    required this.onVersionTap,
    required this.onCheck,
    this.progress,
  });
  final String version;
  final String status;
  final bool checking;
  final bool hasUpdate;
  final VoidCallback onVersionTap;
  final VoidCallback? onCheck;
  final double? progress;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final theme = Theme.of(context);
      final compact = box.maxWidth < 600;
      final versions = version.split('+');
      final info = InkWell(
        key: const Key('about-version-button'),
        onTap: onVersionTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SpacingToken.sm),
          child: Wrap(
            alignment: compact ? WrapAlignment.center : WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: SpacingToken.sm,
            runSpacing: SpacingToken.xs,
            children: [
              if (!compact)
                HugeIcon(
                  icon: HugeIcons.strokeRoundedTag01,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              Text(versions.first, style: theme.textTheme.titleSmall),
              if (versions.length > 1)
                Text(
                  'Build ${versions.last}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      );
      final action = Wrap(
        alignment: compact ? WrapAlignment.center : WrapAlignment.end,
        spacing: SpacingToken.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (status.isNotEmpty)
            Text(
              status,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (onCheck != null)
            FilledButton(
              key: const Key('about-check-update-button'),
              style: FilledButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingToken.lg,
                  vertical: SpacingToken.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusToken.md),
                ),
              ),
              onPressed: checking ? null : onCheck,
              child: Text(
                (checking
                        ? 'settings_update_checking'
                        : hasUpdate
                        ? 'about_view_update'
                        : 'settings_update_check')
                    .tr(),
              ),
            ),
        ],
      );
      return Container(
        key: const Key('about-version-row'),
        padding: const EdgeInsets.symmetric(vertical: SpacingToken.md),
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: .5),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact) ...[
              Center(child: info),
              Center(child: action),
            ] else
              Row(
                children: [
                  info,
                  const SizedBox(width: SpacingToken.lg),
                  Expanded(child: action),
                ],
              ),
            if (progress != null) ...[
              const SizedBox(height: SpacingToken.sm),
              LinearProgressIndicator(value: progress),
            ],
          ],
        ),
      );
    },
  );
}

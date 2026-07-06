import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';

class WelcomeFeature {
  final List<List<dynamic>> icon;
  final String titleKey;
  final String descriptionKey;

  const WelcomeFeature({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
  });
}

/// Reusable welcome and empty-state panel for feature pages.
class Welcome extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String titleKey;
  final String descriptionKey;
  final List<WelcomeFeature> features;
  final Widget? action;
  final double maxWidth;

  const Welcome({
    super.key,
    this.icon = HugeIcons.strokeRoundedSparkles,
    this.titleKey = 'welcome_default_title',
    this.descriptionKey = 'welcome_default_description',
    this.features = const [],
    this.action,
    this.maxWidth = 560,
  });

  const Welcome.chat({super.key})
    : icon = HugeIcons.strokeRoundedChatting01,
      titleKey = 'welcome_chat_title',
      descriptionKey = 'welcome_chat_description',
      features = const [
        WelcomeFeature(
          icon: HugeIcons.strokeRoundedMessage01,
          titleKey: 'welcome_chat_feature_messages_title',
          descriptionKey: 'welcome_chat_feature_messages_description',
        ),
        WelcomeFeature(
          icon: HugeIcons.strokeRoundedCall02,
          titleKey: 'welcome_chat_feature_call_title',
          descriptionKey: 'welcome_chat_feature_call_description',
        ),
        WelcomeFeature(
          icon: HugeIcons.strokeRoundedFileAttachment,
          titleKey: 'welcome_chat_feature_files_title',
          descriptionKey: 'welcome_chat_feature_files_description',
        ),
      ],
      action = null,
      maxWidth = 620;

  const Welcome.contacts({super.key})
    : icon = HugeIcons.strokeRoundedUserGroup,
      titleKey = 'welcome_contacts_title',
      descriptionKey = 'welcome_contacts_description',
      features = const [
        WelcomeFeature(
          icon: HugeIcons.strokeRoundedUserAdd01,
          titleKey: 'welcome_contacts_feature_add_title',
          descriptionKey: 'welcome_contacts_feature_add_description',
        ),
        WelcomeFeature(
          icon: HugeIcons.strokeRoundedUserMultiple,
          titleKey: 'welcome_contacts_feature_groups_title',
          descriptionKey: 'welcome_contacts_feature_groups_description',
        ),
        WelcomeFeature(
          icon: HugeIcons.strokeRoundedUserAccount,
          titleKey: 'welcome_contacts_feature_profile_title',
          descriptionKey: 'welcome_contacts_feature_profile_description',
        ),
      ],
      action = null,
      maxWidth = 620;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 32.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: icon,
                    size: 38,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                titleKey.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                descriptionKey.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
              if (features.isNotEmpty) ...[
                SizedBox(height: 28.h),
                _FeatureGrid(features: features),
              ],
              if (action != null) ...[SizedBox(height: 28.h), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final List<WelcomeFeature> features;

  const _FeatureGrid({required this.features});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (final feature in features)
              SizedBox(
                width: isNarrow ? constraints.maxWidth : 188,
                child: _FeatureItem(feature: feature),
              ),
          ],
        );
      },
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final WelcomeFeature feature;

  const _FeatureItem({required this.feature});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: feature.icon, size: 22, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            feature.titleKey.tr(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            feature.descriptionKey.tr(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

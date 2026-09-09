import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 官方帮助页 - 快速操作入口。
///
/// 纯前端展示，动作列表与点击回调由上层按平台注入。
class QuickActionData {
  const QuickActionData({
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String titleKey;
  final String descKey;
  final VoidCallback onTap;
}

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key, required this.items});

  final List<QuickActionData> items;

  @override
  Widget build(BuildContext context) {
    final gap = 12.0;
    return _Section(
      title: 'official_room_action_title'.tr(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 600 ? 2 : 1;
          final cardWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in items)
                SizedBox(
                  width: cardWidth,
                  child: _ActionCard(item: item),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.item});

  final QuickActionData item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(RadiusToken.lg),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RadiusToken.lg),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(RadiusToken.lg),
                ),
                child: HugeIcon(
                  icon: item.icon,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titleKey.tr(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.descKey.tr(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// 功能一览 - 核心能力卡片。
///
/// 宽屏双列、窄屏单列；纯展示，无需交互。
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  static const List<_FeatureCard> _features = [
    _FeatureCard(
      icon: HugeIcons.strokeRoundedMessageMultiple01,
      titleKey: 'official_room_feat_messages',
      descKey: 'official_room_feat_messages_desc',
    ),
    _FeatureCard(
      icon: HugeIcons.strokeRoundedVideo01,
      titleKey: 'official_room_feat_call',
      descKey: 'official_room_feat_call_desc',
    ),
    _FeatureCard(
      icon: HugeIcons.strokeRoundedSparkles,
      titleKey: 'official_room_feat_ai',
      descKey: 'official_room_feat_ai_desc',
    ),
    _FeatureCard(
      icon: HugeIcons.strokeRoundedNote01,
      titleKey: 'official_room_feat_note',
      descKey: 'official_room_feat_note_desc',
    ),
    _FeatureCard(
      icon: HugeIcons.strokeRoundedFavourite,
      titleKey: 'official_room_feat_favorite',
      descKey: 'official_room_feat_favorite_desc',
    ),
    _FeatureCard(
      icon: HugeIcons.strokeRoundedSticker,
      titleKey: 'official_room_feat_sticker',
      descKey: 'official_room_feat_sticker_desc',
    ),
    _FeatureCard(
      icon: HugeIcons.strokeRoundedSearch01,
      titleKey: 'official_room_feat_search',
      descKey: 'official_room_feat_search_desc',
    ),
    _FeatureCard(
      icon: HugeIcons.strokeRoundedUserMultiple02,
      titleKey: 'official_room_feat_sync',
      descKey: 'official_room_feat_sync_desc',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'official_room_feat_title'.tr(),
      child: Column(
        children: [
          for (var i = 0; i < _features.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == _features.length - 1 ? 0 : 10,
              ),
              child: _FeatureTile(card: _features[i]),
            ),
        ],
      ),
    );
  }
}

/// 功能条目 - 与常见问题一致的可展开面板样式。
class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.card});

  final _FeatureCard card;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          maintainState: true,
          iconColor: colorScheme.onSurfaceVariant,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.transparent),
          ),
          collapsedShape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.transparent),
          ),
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(RadiusToken.lg),
            ),
            child: HugeIcon(
              icon: card.icon,
              size: 19,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          title: Text(
            card.titleKey.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                card.descKey.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard {
  const _FeatureCard({
    required this.icon,
    required this.titleKey,
    required this.descKey,
  });

  final List<List<dynamic>> icon;
  final String titleKey;
  final String descKey;
}

/// 快速上手指引 - 分步流程。
class OnboardingSection extends StatelessWidget {
  const OnboardingSection({super.key});

  static const List<_StepData> _steps = [
    _StepData(
      titleKey: 'official_room_onboarding_step1',
      descKey: 'official_room_onboarding_step1_desc',
    ),
    _StepData(
      titleKey: 'official_room_onboarding_step2',
      descKey: 'official_room_onboarding_step2_desc',
    ),
    _StepData(
      titleKey: 'official_room_onboarding_step3',
      descKey: 'official_room_onboarding_step3_desc',
    ),
    _StepData(
      titleKey: 'official_room_onboarding_step4',
      descKey: 'official_room_onboarding_step4_desc',
    ),
  ];

  /// 宽屏横向布局中连接箭头的固定宽度，与 [_StepConnector] 保持一致。
  static const double _connectorWidth = 20;

  @override
  Widget build(BuildContext context) {
    final gap = 10.0;
    return _Section(
      title: 'official_room_onboarding_title'.tr(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 560;
          if (wide) {
            // 卡片宽度需扣除连接箭头占位，避免 Row 固定宽溢出
            final cardWidth =
                (constraints.maxWidth - _connectorWidth * (_steps.length - 1)) /
                _steps.length;
            return Row(
              children: [
                for (var i = 0; i < _steps.length; i++) ...[
                  if (i > 0) const _StepConnector(),
                  SizedBox(width: cardWidth, child: _OnboardingStep(index: i, step: _steps[i])),
                ],
              ],
            );
          }
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < _steps.length; i++)
                SizedBox(
                  width: (constraints.maxWidth - gap) / 2,
                  child: _OnboardingStep(index: i, step: _steps[i]),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 20,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedArrowRight01,
          size: 16,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _StepData {
  const _StepData({required this.titleKey, required this.descKey});

  final String titleKey;
  final String descKey;
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({required this.index, required this.step});

  final int index;
  final _StepData step;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(RadiusToken.md),
            ),
            child: Text(
              '${index + 1}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            step.titleKey.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(
            step.descKey.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(
              height: 1.4,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}


/// 常见问题 - 可展开折叠列表。
class FaqSection extends StatelessWidget {
  const FaqSection({super.key});

  static const List<_FaqItem> _items = [
    _FaqItem(
      questionKey: 'official_room_faq_q1',
      answerKey: 'official_room_faq_a1',
    ),
    _FaqItem(
      questionKey: 'official_room_faq_q2',
      answerKey: 'official_room_faq_a2',
    ),
    _FaqItem(
      questionKey: 'official_room_faq_q3',
      answerKey: 'official_room_faq_a3',
    ),
    _FaqItem(
      questionKey: 'official_room_faq_q4',
      answerKey: 'official_room_faq_a4',
    ),
    _FaqItem(
      questionKey: 'official_room_faq_q5',
      answerKey: 'official_room_faq_a5',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'official_room_faq_title'.tr(),
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == _items.length - 1 ? 0 : 10),
              child: _FaqTile(item: _items[i]),
            ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item});

  final _FaqItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          maintainState: true,
          iconColor: colorScheme.onSurfaceVariant,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.transparent),
          ),
          collapsedShape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.transparent),
          ),
          leading: Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(RadiusToken.md),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedInformationCircle,
              size: 15,
              color: colorScheme.primary,
            ),
          ),
          title: Text(
            item.questionKey.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.answerKey.tr(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.questionKey, required this.answerKey});

  final String questionKey;
  final String answerKey;
}

/// 小贴士 - 常用技巧提示。
class TipsSection extends StatelessWidget {
  const TipsSection({super.key});

  static const List<_TipData> _tips = [
    _TipData(
      icon: HugeIcons.strokeRoundedPin02,
      titleKey: 'official_room_tip_pin',
      descKey: 'official_room_tip_pin_desc',
    ),
    _TipData(
      icon: HugeIcons.strokeRoundedNotificationOff02,
      titleKey: 'official_room_tip_dnd',
      descKey: 'official_room_tip_dnd_desc',
    ),
    _TipData(
      icon: HugeIcons.strokeRoundedSmartPhone01,
      titleKey: 'official_room_tip_sync',
      descKey: 'official_room_tip_sync_desc',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final gap = 10.0;
    return _Section(
      title: 'official_room_tips_title'.tr(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 560;
          final cardWidth = wide
              ? (constraints.maxWidth - gap * (_tips.length - 1)) / _tips.length
              : constraints.maxWidth;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final tip in _tips)
                SizedBox(width: cardWidth, child: _TipView(tip: tip)),
            ],
          );
        },
      ),
    );
  }
}

class _TipView extends StatelessWidget {
  const _TipView({required this.tip});

  final _TipData tip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: tip.icon,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip.titleKey.tr(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tip.descKey.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(
                height: 1.45,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipData {
  const _TipData({required this.icon, required this.titleKey, required this.descKey});

  final List<List<dynamic>> icon;
  final String titleKey;
  final String descKey;
}

/// 快捷导航入口。
class NavLinksSection extends StatelessWidget {
  const NavLinksSection({super.key, required this.items, this.columns = 1});

  final List<NavLinkData> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'official_room_nav_title'.tr(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnCount = columns > 1 && constraints.maxWidth >= 600
              ? columns
              : 1;
          final gap = 10.0;
          final cardWidth =
              (constraints.maxWidth - gap * (columnCount - 1)) / columnCount;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in items)
                SizedBox(width: cardWidth, child: _NavRow(item: item)),
            ],
          );
        },
      ),
    );
  }
}

class NavLinkData {
  const NavLinkData({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String description;
  final VoidCallback onTap;
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.item});

  final NavLinkData item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(RadiusToken.lg),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RadiusToken.lg),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(RadiusToken.lg),
                ),
                child: HugeIcon(
                  icon: item.icon,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 携带标题的通用区块容器。
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        child,
      ],
    );
  }
}


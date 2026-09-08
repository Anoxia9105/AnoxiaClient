import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 官方帮助页 - 快速操作入口。
///
/// 纯前端展示，所有点击动作由上层通过回调注入。
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    super.key,
    required this.onAddFriend,
    required this.onCreateGroup,
    required this.onCheckUpdate,
    required this.onOpenSettings,
  });

  final VoidCallback onAddFriend;
  final VoidCallback onCreateGroup;
  final VoidCallback onCheckUpdate;
  final VoidCallback onOpenSettings;

  static const List<_ActionSpec> _actions = [
    _ActionSpec(
      icon: HugeIcons.strokeRoundedUserAdd02,
      key: 'official_room_action_add_friend',
      descKey: 'official_room_action_add_friend_desc',
    ),
    _ActionSpec(
      icon: HugeIcons.strokeRoundedUserGroup02,
      key: 'official_room_action_create_group',
      descKey: 'official_room_action_create_group_desc',
    ),
    _ActionSpec(
      icon: HugeIcons.strokeRoundedDownload01,
      key: 'official_room_action_update',
      descKey: 'official_room_action_update_desc',
    ),
    _ActionSpec(
      icon: HugeIcons.strokeRoundedSettings01,
      key: 'official_room_action_settings',
      descKey: 'official_room_action_settings_desc',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final callbacks = [
      onAddFriend,
      onCreateGroup,
      onCheckUpdate,
      onOpenSettings,
    ];
    return _Section(
      title: 'official_room_action_title'.tr(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 600 ? 2 : 1;
          final gap = constraints.maxWidth >= 600 ? 12.0 : 10.0;
          final cardWidth =
              (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: 10,
            children: [
              for (var i = 0; i < _actions.length; i++)
                SizedBox(
                  width: cardWidth,
                  child: _ActionCard(
                    icon: _actions[i].icon,
                    title: _actions[i].key.tr(),
                    description: _actions[i].descKey.tr(),
                    onTap: callbacks[i],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionSpec {
  const _ActionSpec({
    required this.icon,
    required this.key,
    required this.descKey,
  });

  final List<List<dynamic>> icon;
  final String key;
  final String descKey;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(RadiusToken.lg),
      child: InkWell(
        onTap: onTap,
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
                  icon: icon,
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
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

/// 新手上手指引 - 分步流程。
class OnboardingSection extends StatelessWidget {
  const OnboardingSection({super.key});

  static const List<String> _stepKeys = [
    'official_room_onboarding_step1',
    'official_room_onboarding_step2',
    'official_room_onboarding_step3',
    'official_room_onboarding_step4',
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'official_room_onboarding_title'.tr(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final colorScheme = Theme.of(context).colorScheme;
          final wide = constraints.maxWidth >= 560;
          if (wide) {
            return Row(
              children: [
                for (var i = 0; i < _stepKeys.length; i++) ...[
                  if (i > 0) _StepConnector(colors: colorScheme),
                  Expanded(
                    child: _OnboardingStep(index: i, label: _stepKeys[i].tr()),
                  ),
                ],
              ],
            );
          }
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < _stepKeys.length; i++)
                SizedBox(
                  width: (constraints.maxWidth - 10) / 2,
                  child: _OnboardingStep(index: i, label: _stepKeys[i].tr()),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 26),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(RadiusToken.sm),
        ),
      ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({required this.index, required this.label});

  final int index;
  final String label;

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
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(RadiusToken.md),
            ),
            child: Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
          leading: Icon(
            Icons.help_outline,
            size: 20,
            color: colorScheme.primary,
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.45,
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
            runSpacing: 10,
            children: [
              for (var i = 0; i < items.length; i++)
                SizedBox(
                  width: cardWidth,
                  child: _NavRow(item: items[i]),
                ),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

import 'package:anoxia/framework/provider/layout/desktop_layout_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';

/// 设置-桌面布局区块。
class SettingsLayoutSection extends StatelessWidget {
  const SettingsLayoutSection({
    super.key,
    required this.selectedPreference,
    required this.onChanged,
  });

  final DesktopLayoutPreference selectedPreference;
  final ValueChanged<DesktopLayoutPreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      _LayoutOptionData(
        key: const Key('desktop-layout-auto'),
        preference: DesktopLayoutPreference.automatic,
        title: 'settings_layout_auto'.tr(),
        description: 'settings_layout_auto_description'.tr(),
      ),
      _LayoutOptionData(
        key: const Key('desktop-layout-card'),
        preference: DesktopLayoutPreference.card,
        title: 'settings_layout_card'.tr(),
        description: 'settings_layout_card_description'.tr(),
      ),
      _LayoutOptionData(
        key: const Key('desktop-layout-flat'),
        preference: DesktopLayoutPreference.flat,
        title: 'settings_layout_flat'.tr(),
        description: 'settings_layout_flat_description'.tr(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings_layout_title'.tr(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'settings_layout_description'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: SpacingToken.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 680;
            final children = options
                .map(
                  (option) => _LayoutOption(
                    data: option,
                    selected: selectedPreference == option.preference,
                    onTap: () => onChanged(option.preference),
                  ),
                )
                .toList(growable: false);

            if (!horizontal) {
              return Column(
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index != children.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    Expanded(child: children[index]),
                    if (index != children.length - 1) const SizedBox(width: 10),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LayoutOptionData {
  const _LayoutOptionData({
    required this.key,
    required this.preference,
    required this.title,
    required this.description,
  });

  final Key key;
  final DesktopLayoutPreference preference;
  final String title;
  final String description;
}

class _LayoutOption extends StatelessWidget {
  const _LayoutOption({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _LayoutOptionData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      button: true,
      selected: selected,
      label: data.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: data.key,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(RadiusToken.lg),
          onTap: onTap,
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(SpacingToken.md),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.36)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(RadiusToken.lg),
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.72),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LayoutPreview(preference: data.preference, selected: selected),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected)
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedTick01,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: SpacingToken.xs),
                Text(
                  data.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LayoutPreview extends StatelessWidget {
  const _LayoutPreview({required this.preference, required this.selected});

  final DesktopLayoutPreference preference;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final cardMode = preference != DesktopLayoutPreference.flat;

    return Container(
      height: 56,
      padding: EdgeInsets.all(cardMode ? 6 : 0),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(RadiusToken.md),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.52),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: cardMode
                  ? BorderRadius.circular(RadiusToken.sm)
                  : BorderRadius.zero,
              border: Border(
                right: BorderSide(color: accent.withValues(alpha: 0.28)),
              ),
            ),
          ),
          SizedBox(width: cardMode ? 6 : 0),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: cardMode
                    ? BorderRadius.circular(RadiusToken.sm)
                    : BorderRadius.zero,
                border: cardMode
                    ? Border.all(color: accent.withValues(alpha: 0.2))
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

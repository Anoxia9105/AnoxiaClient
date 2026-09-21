import 'package:anoxia/framework/provider/chat/message/chat_content_density_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';

class SettingsChatDensitySection extends StatelessWidget {
  const SettingsChatDensitySection({
    super.key,
    required this.selectedDensity,
    required this.onChanged,
  });

  final ChatContentDensity selectedDensity;
  final ValueChanged<ChatContentDensity> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (ChatContentDensity.comfortable, 'comfortable'),
      (ChatContentDensity.compact, 'compact'),
      (ChatContentDensity.flat, 'flat'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings_chat_density_title'.tr(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'settings_chat_density_description'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: SpacingToken.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = options
                .map((option) {
                  final (density, name) = option;
                  return _DensityOption(
                    key: Key('chat-density-$name'),
                    density: density,
                    selected: selectedDensity == density,
                    onTap: () => onChanged(density),
                  );
                })
                .toList(growable: false);

            if (constraints.maxWidth < 680) {
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    cards[i],
                    if (i != cards.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i != cards.length - 1) const SizedBox(width: 10),
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

class _DensityOption extends StatelessWidget {
  const _DensityOption({
    super.key,
    required this.density,
    required this.selected,
    required this.onTap,
  });

  final ChatContentDensity density;
  final bool selected;
  final VoidCallback onTap;

  String get name => density.storageValue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RadiusToken.lg),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(SpacingToken.md),
            decoration: BoxDecoration(
              color: selected
                  ? colors.primaryContainer.withValues(alpha: 0.36)
                  : colors.surfaceContainerHighest.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(RadiusToken.lg),
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DensityPreview(density: density, selected: selected),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'settings_chat_density_$name'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: selected ? colors.primary : colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected)
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedTick01,
                        size: 18,
                        color: colors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: SpacingToken.xs),
                Text(
                  'settings_chat_density_${name}_description'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
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

class _DensityPreview extends StatelessWidget {
  const _DensityPreview({required this.density, required this.selected});

  final ChatContentDensity density;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compact = density == ChatContentDensity.compact;
    final flat = density == ChatContentDensity.flat;
    final accent = selected ? colors.primary : colors.onSurfaceVariant;
    return Container(
      height: 56,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(RadiusToken.md),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.52),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PreviewMessage(
            left: true,
            width: 44,
            height: compact ? 4 : 6,
            color: accent,
          ),
          _PreviewMessage(
            left: flat,
            width: 60,
            height: compact ? 4 : 6,
            color: accent,
          ),
          if (compact)
            _PreviewMessage(left: true, width: 50, height: 4, color: accent),
        ],
      ),
    );
  }
}

class _PreviewMessage extends StatelessWidget {
  const _PreviewMessage({
    required this.left,
    required this.width,
    required this.height,
    required this.color,
  });

  final bool left;
  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.32),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: SpacingToken.xs),
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(RadiusToken.sm),
            ),
          ),
        ],
      ),
    );
  }
}

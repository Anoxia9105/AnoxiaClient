import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class SettingsChatFocusSection extends StatelessWidget {
  const SettingsChatFocusSection({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings_chat_focus_title'.tr(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(12),
          child: SwitchListTile.adaptive(
            key: const Key('chat-focus-mode-switch'),
            value: enabled,
            onChanged: onChanged,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            secondary: HugeIcon(
              icon: HugeIcons.strokeRoundedChangeScreenMode,
              size: 20,
              color: enabled ? colors.primary : colors.onSurfaceVariant,
            ),
            title: Text(
              'settings_chat_focus_enable'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'settings_chat_focus_description'.tr(),
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.35),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: enabled ? colors.primary : colors.outlineVariant,
                width: enabled ? 1.4 : 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

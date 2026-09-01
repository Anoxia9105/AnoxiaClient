import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 官方虚拟房间的静态帮助内容。
///
/// 使用直接可见的信息卡，不需要展开操作；窄屏单列、宽屏双列。
class OfficialRoomHelpPanel extends StatelessWidget {
  const OfficialRoomHelpPanel({super.key, this.showTitle = true});

  final bool showTitle;

  static const List<_HelpItem> _items = [
    _HelpItem(
      icon: HugeIcons.strokeRoundedUserAdd02,
      titleKey: 'official_room_help_add_friend',
      descKey: 'official_room_help_add_friend_desc',
    ),
    _HelpItem(
      icon: HugeIcons.strokeRoundedUserGroup02,
      titleKey: 'official_room_help_create_group',
      descKey: 'official_room_help_create_group_desc',
    ),
    _HelpItem(
      icon: HugeIcons.strokeRoundedMessageMultiple01,
      titleKey: 'official_room_help_message_types',
      descKey: 'official_room_help_message_types_desc',
    ),
    _HelpItem(
      icon: HugeIcons.strokeRoundedVideo01,
      titleKey: 'official_room_help_call',
      descKey: 'official_room_help_call_desc',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 640;
        final cardWidth = useTwoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTitle) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                child: Text(
                  'official_room_help_title'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                for (final item in _items)
                  SizedBox(
                    width: cardWidth,
                    child: _HelpCard(item: item),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.item});

  final _HelpItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = item.titleKey.tr();
    final description = item.descKey.tr();

    return Semantics(
      container: true,
      label: '$title。$description',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(RadiusToken.lg),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(RadiusToken.lg),
                  ),
                  child: HugeIcon(
                    icon: item.icon,
                    size: 20,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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

class _HelpItem {
  const _HelpItem({
    required this.icon,
    required this.titleKey,
    required this.descKey,
  });

  final List<List<dynamic>> icon;
  final String titleKey;
  final String descKey;
}

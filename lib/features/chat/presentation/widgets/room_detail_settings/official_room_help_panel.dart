import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';

/// 官方虚拟房间右侧「选项式帮助」面板
///
/// 替代原本的成员网格 / 资料 / 危险操作，展示可展开的功能引导。
class OfficialRoomHelpPanel extends StatelessWidget {
  const OfficialRoomHelpPanel({super.key});

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
    final color = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'official_room_help_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        ..._items.map(
          (item) => Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ExpansionTile(
              leading: HugeIcon(icon: item.icon, size: 22, color: color.primary),
              title: Text(item.titleKey.tr()),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    item.descKey.tr(),
                    style: TextStyle(
                      color: color.onSurface.withValues(alpha: 0.72),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HelpItem {
  final List<List<dynamic>> icon;
  final String titleKey;
  final String descKey;

  const _HelpItem({
    required this.icon,
    required this.titleKey,
    required this.descKey,
  });
}

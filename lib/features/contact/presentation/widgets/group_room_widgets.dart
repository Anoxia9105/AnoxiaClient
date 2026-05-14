import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class GroupRoomEmptyState extends StatelessWidget {
  const GroupRoomEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('group_no_groups'.tr()));
  }
}

class GroupRoomTile extends StatelessWidget {
  final String avatar;
  final String roomName;
  final String subtitle;
  final int unreadCount;

  const GroupRoomTile({
    super.key,
    required this.avatar,
    required this.roomName,
    required this.subtitle,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AvatarWidget(url: avatar, name: roomName),
      title: Text(roomName),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: unreadCount > 0
          ? CircleAvatar(
              radius: 10,
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(fontSize: 12),
              ),
            )
          : null,
    );
  }
}

import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/vibrating_badge.dart';
import 'package:flutter/material.dart';

/// 群聊列表项组件
///
/// 展示群聊头像、名称、最新消息、成员数和未读数
class GroupRoomTile extends StatelessWidget {
  final String avatar;
  final String roomName;
  final String subtitle;
  final int unreadCount;
  final int memberCount;
  final VoidCallback? onTap;

  const GroupRoomTile({
    super.key,
    required this.avatar,
    required this.roomName,
    required this.subtitle,
    required this.unreadCount,
    required this.memberCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: AvatarWidget(url: avatar, name: roomName),
      title: Text('$roomName ($memberCount)'),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: VibratingBadge(count: unreadCount),
    );
  }
}

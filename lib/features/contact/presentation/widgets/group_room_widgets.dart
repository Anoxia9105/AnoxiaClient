import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/VibratingBadge.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 群聊列表页面相关组件集合

/// 空状态组件
///
/// 当用户没有加入任何群聊时显示的提示
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

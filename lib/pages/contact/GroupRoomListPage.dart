import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../framework/provider/chat/room/room_list_service.dart';

class GroupRoomListPage extends ConsumerWidget {
  const GroupRoomListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupRoomListProvider);

    if (groups.isEmpty) {
      return const Center(child: Text("暂无群聊"));
    }

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final room = groups[index];
        return ListTile(
          leading: AvatarWidget(url: room.roomAvatar, name: room.roomName),
          title: Text(room.roomName ?? '未命名群聊'),
          subtitle: Text(
            room.lastMessage?.content ?? '暂无消息',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: (room.unreadCount ?? 0) > 0
              ? CircleAvatar(
                  radius: 10,
                  child: Text(
                    room.unreadCount.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                )
              : null,
        );
      },
    );
  }
}

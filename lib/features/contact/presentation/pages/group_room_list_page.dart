import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/contact/presentation/widgets/group_room_widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../framework/provider/chat/room/room_list_service.dart';

class GroupRoomListPage extends ConsumerWidget {
  const GroupRoomListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupRoomListProvider);

    return Scaffold(
      backgroundColor: DeviceUtil.isRealDesktop()
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text('contact_joined_groups'.tr())),
      body: groups.isEmpty
          ? const GroupRoomEmptyState()
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final room = groups[index];
                return GroupRoomTile(
                  avatar: room.roomAvatar ?? '',
                  roomName: room.roomName ?? 'group_unnamed'.tr(),
                  subtitle:
                      room.lastMessage?.content ??
                      'chat_no_messages_in_group'.tr(),
                  unreadCount: room.unreadCount ?? 0,
                );
              },
            ),
    );
  }
}

import 'package:anoxia/common/utils/DateUtil.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/VibratingBadge.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_page.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/room/pinned_rooms_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class RoomListItem extends ConsumerWidget {
  final ChatRoomVO room;

  const RoomListItem({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeRoomIdProvider);
    final isSelected = activeId == room.roomId;
    final isSingle = room.roomType == 0;

    final contactMap = ref.watch(contactListServiceProvider).value;
    final peerContact = (isSingle && room.peerId != null && contactMap != null)
        ? contactMap[room.peerId]
        : null;

    final displayRoomName = isSingle
        ? (() {
            final remark = (peerContact?.remark ?? '').trim();
            if (remark.isNotEmpty) return remark;

            final nickName = (peerContact?.nickName ?? '').trim();
            if (nickName.isNotEmpty) return nickName;

            final roomName = (room.roomName ?? '').trim();
            if (roomName.isNotEmpty) return roomName;

            return 'chat_unknown_conversation'.tr();
          })()
        : (room.roomName?.trim().isNotEmpty == true
              ? room.roomName!.trim()
              : 'chat_unknown_conversation'.tr());

    final pinnedIds = ref.watch(pinnedRoomsProvider);
    final roomId = room.roomId;
    final isPinned = roomId != null && pinnedIds.contains(room.roomId);

    bool isOnline = false;
    if (isSingle && room.peerId != null) {
      isOnline = peerContact?.onlineStatus ?? false;
    }

    return GestureDetector(
      /// 右键点击（桌面）或长按（移动端）显示上下文菜单
      onSecondaryTapDown: (details) async {
        if (roomId == null) return;
        await ref.read(roomMemberServiceProvider.notifier).syncMembers(roomId);
        if (context.mounted) {
          _showContextMenu(
            context,
            ref,
            details.globalPosition,
            room,
            isPinned,
          );
        }
      },

      /// 长按开始时也显示上下文菜单，兼容部分不支持 onSecondaryTapDown 的设备（如部分 Android 机型）
      onLongPressStart: (details) async {
        if (roomId == null) return;
        await ref.read(roomMemberServiceProvider.notifier).syncMembers(roomId);
        if (context.mounted) {
          _showContextMenu(
            context,
            ref,
            details.globalPosition,
            room,
            isPinned,
          );
        }
      },
      child: ListTile(
        onTap: () async {
          if (room.roomId != null) {
            ref.read(activeRoomIdProvider.notifier).setActive(room.roomId!);

            if (DeviceUtil.isRealMobile()) {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChatRoomDetail(room: room)),
              );

              // 移动端从详情页返回列表后，清空 active 房间：
              // 否则该房间会一直被视为“当前房间”，导致未读数不再累加。
              if (context.mounted) {
                ref.read(activeRoomIdProvider.notifier).setActive(null);
              }
            }
          }
        },
        selected: isSelected,
        leading: AvatarWidget(
          url: room.roomAvatar,
          name: room.roomName,
          status: isSingle
              ? (isOnline ? AvatarStatus.online : AvatarStatus.offline)
              : AvatarStatus.none,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayRoomName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 6),
            HugeIcon(
              icon: isSingle
                  ? HugeIcons.strokeRoundedUser02
                  : HugeIcons.strokeRoundedUserGroup03,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
              strokeWidth: 2,
            ),
          ],
        ),
        subtitle: Text(
          room.lastMessage?.content ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),

        /// 右侧显示最后消息时间和未读数
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPinned) ...[
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedPin,
                      size: 14,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    DateUtil.formatTime(room.lastMessage?.timestamp),
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              VibratingBadge(count: room.unreadCount ?? 0),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset globalPosition,
    ChatRoomVO room,
    bool isPinned,
  ) async {
    final roomId = room.roomId;
    if (roomId == null) return;

    final userId = ref.read(authControllerProvider).value?.userId;
    final members = ref.read(roomMembersProvider(roomId));
    final me = members.firstWhere((m) => m.userId == userId);
    final canDissolve = me.roleId == 0;

    final position = RelativeRect.fromLTRB(
      globalPosition.dx,
      globalPosition.dy,
      globalPosition.dx,
      globalPosition.dy,
    );

    final items = <PopupMenuEntry<String>>[
      _buildMenuItem(
        icon: isPinned
            ? HugeIcons.strokeRoundedPinOff
            : HugeIcons.strokeRoundedPin,
        label: isPinned ? 'chat_unpin'.tr() : 'chat_pin'.tr(),
        value: 'pin',
      ),
      _buildMenuItem(
        icon: HugeIcons.strokeRoundedCheckmarkBadge01,
        label: 'chat_mark_as_read'.tr(),
        value: 'read',
      ),
      const PopupMenuDivider(height: 1),
      if (!canDissolve)
        _buildMenuItem(
          icon: HugeIcons.strokeRoundedDelete02,
          label: 'chat_delete_conversation'.tr(),
          value: 'hide',
          color: Theme.of(context).colorScheme.error,
        ),
      if (canDissolve)
        _buildMenuItem(
          icon: HugeIcons.strokeRoundedDelete02,
          label: 'chat_dissolve_group'.tr(),
          value: 'dissolve',
          color: Theme.of(context).colorScheme.error,
        ),
    ];

    final result = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      items: items,
    );

    if (result == null) return;
    final roomList = ref.read(roomListServiceProvider.notifier);
    final activeRoomId = ref.read(activeRoomIdProvider);

    switch (result) {
      case 'pin':
        await ref.read(pinnedRoomsProvider.notifier).toggle(roomId);
        break;
      case 'read':
        roomList.markAsRead(roomId);
        break;
      case 'hide':
      case 'leave':
        await roomList.leaveRoom(roomId);
        if (activeRoomId == roomId) {
          ref.read(activeRoomIdProvider.notifier).setActive(null);
        }
        break;
      case 'dissolve':
        await roomList.dissolveGroup(roomId);
        if (activeRoomId == roomId) {
          ref.read(activeRoomIdProvider.notifier).setActive(null);
        }
        break;
    }
  }

  /// 构建上下文菜单项
  PopupMenuItem<String> _buildMenuItem({
    required dynamic icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, color: color)),
        ],
      ),
    );
  }
}

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

/// 房间列表项组件
///
/// 显示单个聊天房间的列表项，包括：
/// - 房间头像和在线状态
/// - 房间名称（支持备注名优先显示）
/// - 最后消息预览
/// - 时间戳
/// - 未读消息数
/// - 置顶标识
///
/// 支持右键菜单（桌面端）和长按菜单（移动端）
class RoomListItem extends ConsumerWidget {
  /// 房间 ID
  final String id;

  const RoomListItem({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(currentRoomProvider(id));

    // 如果房间数据不存在，直接渲染占位结构
    if (room == null) return const SizedBox.shrink();

    final activeId = ref.watch(activeRoomIdProvider);
    final isSelected = activeId == room.roomId;
    final isSingle = room.roomType == 0;

    // 监听联系人状态，用于显示备注名
    final contactMap = ref.watch(contactListServiceProvider).value;
    final peerContact = (isSingle && room.peerId != null && contactMap != null)
        ? contactMap[room.peerId]
        : null;

    // 计算展示的名字：备注名 > 联系人昵称 > 房间名
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

    // 置顶与在线状态计算
    final pinnedIds = ref.watch(pinnedRoomsProvider);
    final roomId = room.roomId;
    final isPinned = roomId != null && pinnedIds.contains(room.roomId);

    bool isOnline = false;
    if (isSingle && room.peerId != null) {
      isOnline = peerContact?.onlineStatus ?? false;
    }

    return GestureDetector(
      // 右键点击（桌面端）显示上下文菜单
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

      // 长按（移动端）显示上下文菜单
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
                MaterialPageRoute(
                  builder: (_) => ChatRoomDetail(roomId: room.roomId!),
                ),
              );

              // 移动端从详情页返回列表后，清空 active 房间
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
        title: Text(
          displayRoomName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          room.lastMessage?.content ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        // 右侧显示最后消息时间和未读数
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
                  // 单聊显示个人图标，群聊显示群组图标
                  HugeIcon(
                    icon: isSingle
                        ? HugeIcons.strokeRoundedUser02
                        : HugeIcons.strokeRoundedUserGroup03,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 6),
                  // 置顶图标
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

  /// 显示上下文菜单
  ///
  /// 提供置顶/取消置顶、标记已读、删除会话、解散群聊等操作
  Future<void> _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset globalPosition,
    ChatRoomVO room,
    bool isPinned,
  ) async {
    final roomId = room.roomId;
    if (roomId == null) return;

    final currentUser = ref.read(authControllerProvider).value;
    // 当前用户是否是管理员
    final isAdmin = ref.watch(
      isRoomAdminProvider((roomId, currentUser?.userId ?? 0)),
    );

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

      if (isAdmin && room.roomStatus == 0)
        _buildMenuItem(
          icon: HugeIcons.strokeRoundedDelete02,
          label: 'chat_dissolve_group'.tr(),
          value: 'dissolve',
          color: Theme.of(context).colorScheme.error,
        )
      else
        _buildMenuItem(
          icon: HugeIcons.strokeRoundedDelete02,
          label: 'chat_delete_conversation'.tr(),
          value: 'hide',
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

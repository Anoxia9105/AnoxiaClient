import 'package:anoxia/common/utils/date_util.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/dialogs/danger_confirm_dialog.dart';
import 'package:anoxia/common/widgets/simple_list_tile.dart';
import 'package:anoxia/common/widgets/vibrating_badge.dart';
import 'package:anoxia/features/chat/presentation/formatters/message_preview_formatter.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_page.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/room/do_not_disturb_rooms_provider.dart';
import 'package:anoxia/framework/provider/chat/room/pinned_rooms_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 房间列表项组件
///
/// 显示单个聊天房间的列表项，包括：
/// - 房间头像和在线状态
/// - 房间名称（支持备注名优先显示）
/// - 最后消息预览
/// - 时间戳
/// - 未读消息数（免打扰时该位置改为展示免打扰图标）
/// - 置顶标识
/// - 免打扰标识（位于右下角未读数的位置，所有端统一）
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
    final isOfficial = room.isOfficial;

    // 监听联系人状态，用于显示备注名
    final contactMap = ref.watch(contactListServiceProvider).value;
    final peerContact = (isSingle && room.peerId != null && contactMap != null)
        ? contactMap[room.peerId]
        : null;

    // 计算展示的名字：备注名 > 联系人昵称 > 房间名
    final displayRoomName = isOfficial
        ? 'official_room_name'.tr()
        : isSingle
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
    final isDoNotDisturb =
        roomId != null && ref.watch(doNotDisturbRoomsProvider).contains(roomId);

    bool isOnline = false;
    if (isSingle && room.peerId != null) {
      isOnline = peerContact?.onlineStatus ?? false;
    }

    final tile = SimpleListTile(
      onTap: () async {
        if (room.roomId != null) {
          if (isOfficial) {
            ref.read(chatRightPanelVisibleProvider.notifier).state = false;
          }
          ref.read(activeRoomIdProvider.notifier).setActive(room.roomId!);

          // 用宽度断点判定布局（与 chat_page.dart 一致），而非 isRealMobile()。
          // 否则 Web 上的窄屏（手机浏览器）会被判为“非真实移动设备”，
          // 点击会话既不 push 路由、页面上也没有 ChatRoomDetail，表现为“点击无响应”。
          if (DeviceUtil.isMobile(context)) {
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
      borderRadius: BorderRadius.circular(8),
      selected: isSelected,
      leading: () {
        if (isOfficial) {
          final cs = Theme.of(context).colorScheme;
          return Tooltip(
            message: displayRoomName,
            child: Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
              ),
              child: Assets.images.appIconPng.image(
                fit: BoxFit.contain,
                semanticLabel: displayRoomName,
              ),
            ),
          );
        }
        if (isSingle) {
          return AvatarWidget(
            url: room.roomAvatar,
            name: displayRoomName,
            status: isOnline ? AvatarStatus.online : AvatarStatus.offline,
          );
        }
        final cs = Theme.of(context).colorScheme;
        return AvatarWidget(
          url: room.roomAvatar,
          name: displayRoomName,
          statusWidget: Tooltip(
            message: 'chat_type_group'.tr(),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withValues(alpha: 0.92),
                    cs.primary.withValues(alpha: 0.6),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.28),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedUserGroup03,
                size: 10,
                strokeWidth: 2,
                color: cs.onPrimary,
              ),
            ),
          ),
        );
      }(),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayRoomName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Text(
            DateUtil.formatTime(room.lastMessage?.timestamp),
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      subtitle: Text(
        isOfficial
            ? 'official_room_list_hint'.tr()
            : _lastMessagePreview(room.lastMessage),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: SizedBox(
        width: 44,
        height: 44,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isPinned)
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedPin02,
                      size: 16,
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 20,
              child: isDoNotDisturb
                  // 免打扰时，右下角（未读数位置）改为展示免打扰图标，
                  // 既提示静音状态，又避免未读数角标打扰用户。所有端统一生效。
                  ? Tooltip(
                      message: 'chat_do_not_disturb'.tr(),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedNotificationOff02,
                        size: 15,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    )
                  : VibratingBadge(count: room.unreadCount ?? 0),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      // 右键点击（桌面端）显示上下文菜单
      onSecondaryTapDown: (details) async {
        if (roomId == null || isOfficial) return;
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
        if (roomId == null || isOfficial) return;
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
      child: tile,
    );
  }

  String _lastMessagePreview(ChatMessage? message) {
    return MessagePreviewFormatter.format(message);
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
    final isAdmin = ref.read(
      isRoomAdminProvider((roomId, currentUser?.userId ?? 0)),
    );
    final isDoNotDisturb = ref.read(doNotDisturbRoomsProvider).contains(roomId);

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
        icon: isDoNotDisturb
            ? HugeIcons.strokeRoundedNotification02
            : HugeIcons.strokeRoundedNotificationOff02,
        label: isDoNotDisturb
            ? 'chat_enable_notifications'.tr()
            : 'chat_do_not_disturb'.tr(),
        value: 'notifications',
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
    if (!context.mounted) return;
    final roomList = ref.read(roomListServiceProvider.notifier);
    final activeRoomId = ref.read(activeRoomIdProvider);

    switch (result) {
      case 'pin':
        await ref.read(pinnedRoomsProvider.notifier).toggle(roomId);
        break;
      case 'notifications':
        await ref.read(doNotDisturbRoomsProvider.notifier).toggle(roomId);
        break;
      case 'read':
        roomList.markAsRead(roomId);
        break;
      case 'hide':
        final confirmed = await _showDeleteConversationConfirm(context);
        if (!confirmed) return;
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

  Future<bool> _showDeleteConversationConfirm(BuildContext context) {
    return showDangerConfirmDialog(
      context,
      icon: HugeIcons.strokeRoundedDelete02,
      title: 'chat_delete_conversation'.tr(),
      content: 'chat_delete_conversation_confirm_hint'.tr(),
      confirmLabel: 'chat_delete_conversation'.tr(),
    );
  }

  /// 构建上下文菜单项
  PopupMenuItem<String> _buildMenuItem({
    required List<List<dynamic>> icon,
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

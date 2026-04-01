import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/domain/ChatRoomMemberVO.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/pages/chat/component/widget/CreateChatDialogWidget.dart';
import 'package:anoxia/pages/contact/AddFriendPage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../common/utils/DateUtil.dart';
import '../../../common/widgets/AvatarWidget.dart';
import '../../../common/widgets/VibratingBadge.dart';
import '../../../framework/domain/ChatRoomVO.dart';
import '../../../framework/provider/auth/auth_controller.dart';
import '../../../framework/provider/chat/room/pinned_rooms_provider.dart';
import '../../../framework/provider/chat/room/room_list_service.dart';
import '../../../framework/provider/chat/room/room_member_service.dart';

class ChatRoomList extends ConsumerStatefulWidget {
  const ChatRoomList({super.key});

  @override
  ConsumerState createState() => _ChatRoomListState();
}

class _ChatRoomListState extends ConsumerState<ChatRoomList> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomListAsync = ref.watch(roomListServiceProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Expanded(
              child: SizedBox(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) =>
                      ref.read(roomSearchQueryProvider.notifier).update(val),
                  maxLength: 20,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    counterText: '',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    // 当有文字时显示清除按钮
                    suffixIcon: ref.watch(roomSearchQueryProvider).isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(roomSearchQueryProvider.notifier)
                                  .update("");
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'chat_search_placeholder'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Builder(
              builder: (context) {
                return IconButton(
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedLayerAdd),
                  onPressed: () => _showAddRoomDetail(context),
                );
              },
            ),
          ],
        ),
      ),
      body: roomListAsync.when(
        data: (rooms) => _buildRoomList(context, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('chat_load_failed'.tr())),
      ),
    );
  }

  void _showAddRoomDetail(BuildContext context) {
    Function? close;
    close = Toast.showWidget(
      context,
      direction: PreferDirection.bottomLeft,
      child: Material(
        color: Colors.transparent,
        child: BubbleWidget(
          arrowDirection: AxisDirection.up,
          arrowOffset: 25,
          backgroundColor: Theme.of(context).colorScheme.surface,
          border: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
          contentBuilder: (context) => Container(
            constraints: BoxConstraints(maxWidth: 220, maxHeight: 600),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return CreateChatDialogWidget();
                        },
                      );
                      close?.call();
                    },
                    label: Text('chat_create_group'.tr()),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedChatting01,
                      size: 18,
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      close?.call();
                      // TODO: 显示添加好友弹框
                      _showAddFriendDialog(context, ref);
                    },
                    label: Text('chat_add_friend'.tr()),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedUserAdd01,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建列表主体
  Widget _buildRoomList(BuildContext context, WidgetRef ref) {
    final filteredRooms = ref.watch(filteredRoomListProvider);
    final query = ref.watch(roomSearchQueryProvider);
    final pinnedIds = ref.watch(pinnedRoomsProvider);

    if (filteredRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              query.isEmpty
                  ? 'chat_no_conversations'.tr()
                  : 'chat_no_related_conversations'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    // 置顶的排前面；同组内保持原顺序（稳定分组）
    final pinned = <ChatRoomVO>[];
    final normal = <ChatRoomVO>[];
    for (final r in filteredRooms) {
      final id = r.roomId;
      if (id != null && pinnedIds.contains(id)) {
        pinned.add(r);
      } else {
        normal.add(r);
      }
    }
    final sortedRooms = <ChatRoomVO>[...pinned, ...normal];

    return RefreshIndicator(
      onRefresh: () => ref.read(roomListServiceProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sortedRooms.length,
        itemBuilder: (context, index) {
          return _RoomItem(room: sortedRooms[index]);
        },
        clipBehavior: Clip.hardEdge, // 限制内容只在边界内绘制
      ),
    );
  }

  /// 显示添加好友弹框
  void _showAddFriendDialog(BuildContext context, WidgetRef ref) {
    final isDesktop = DeviceUtil.isRealDesktop();
    final dialogWidth = isDesktop ? 900.0 : 400.0;
    final dialogHeight = isDesktop ? 700.0 : 600.0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: const AddFriendPage(),
        ),
      ),
    );
  }
}

// 抽离单个会话项，提高性能
class _RoomItem extends ConsumerWidget {
  final ChatRoomVO room;

  const _RoomItem({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeRoomIdProvider);
    final isSelected = activeId == room.roomId;
    final isSingle = room.roomType == 0;

    final pinnedIds = ref.watch(pinnedRoomsProvider);
    final roomId = room.roomId;
    final isPinned = roomId != null && pinnedIds.contains(room.roomId);

    // 如果是单聊 (roomType == 0)，我们去联系人服务里找对方的在线状态
    bool isOnline = false;
    if (isSingle && room.peerId != null) {
      isOnline = ref.watch(
        contactListServiceProvider.select((asyncMap) {
          final contact = asyncMap.value?[room.peerId];
          return contact?.onlineStatus ?? false;
        }),
      );
    }

    return GestureDetector(
      onSecondaryTapDown: (details) async {
        if (roomId == null) return;
        await ref.read(roomMemberServiceProvider.notifier).syncMembers(roomId);
        _showContextMenu(context, ref, details.globalPosition, isPinned);
      },
      onLongPressStart: (details) async {
        if (roomId == null) return;
        await ref.read(roomMemberServiceProvider.notifier).syncMembers(roomId);
        _showContextMenu(context, ref, details.globalPosition, isPinned);
      },
      child: ListTile(
        onTap: () {
          if (room.roomId != null) {
            ref.read(activeRoomIdProvider.notifier).setActive(room.roomId!);
          }
        },
        selected: isSelected,
        // 左侧头像
        leading: AvatarWidget(
          url: room.roomAvatar,
          name: room.roomName,
          status: isSingle
              ? (isOnline ? AvatarStatus.online : AvatarStatus.offline)
              : AvatarStatus.none,
        ),
        // 中间名称和最后消息
        title: Text(
          room.roomName ?? 'chat_unknown_conversation'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          (room.lastMessage?.content ?? ""),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
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
              // VibratingBadge(count: room.unreadCount ?? 0),
              VibratingBadge(isDot: (room.unreadCount ?? 0) > 0),
            ],
          ),
        ),
      ),
    );
  }

  // 显示右键菜单
  void _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset globalPosition,
    bool isPinned,
  ) {
    final roomId = room.roomId;
    if (roomId == null) return;

    final RelativeRect position = RelativeRect.fromLTRB(
      globalPosition.dx,
      globalPosition.dy,
      globalPosition.dx,
      globalPosition.dy,
    );

    final user = ref.read(authControllerProvider).value;
    final currentUserId = user?.userId;

    // 群聊内：只有 roleId==0（群主/创建者）才显示“解散群聊”

    final members = ref.read(roomMembersProvider(roomId));

    final ChatRoomMemberVO? me = members
        .where((m) => m.userId == currentUserId)
        .firstOrNull;
    bool canDissolve = me?.roleId == 0;

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      items: [
        PopupMenuItem(
          value: 'pin',
          height: 36,
          child: Row(
            children: [
              HugeIcon(
                icon: isPinned
                    ? HugeIcons.strokeRoundedPinOff
                    : HugeIcons.strokeRoundedPin,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isPinned ? 'chat_unpin'.tr() : 'chat_pin'.tr(),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'read',
          height: 36,
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                'chat_mark_as_read'.tr(),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        if (!canDissolve)
          PopupMenuItem(
            value: 'hide',
            height: 36,
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'chat_delete_conversation'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        if (canDissolve)
          PopupMenuItem(
            value: 'dissolve',
            height: 36,
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'chat_dissolve_group'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
      ],
    ).then((value) async {
      if (value == null) return;

      switch (value) {
        case 'pin':
          await ref.read(pinnedRoomsProvider.notifier).toggle(roomId);
          break;
        case 'read':
          ref.read(roomListServiceProvider.notifier).markAsRead(roomId);
          break;
        case 'hide':
          await ref.read(roomListServiceProvider.notifier).leaveRoom(roomId);
          // 如果当前正在该会话，清空选中
          final activeId = ref.read(activeRoomIdProvider);
          if (activeId == roomId) {
            ref.read(activeRoomIdProvider.notifier).setActive(null);
          }
          break;
        case 'leave':
          await ref.read(roomListServiceProvider.notifier).leaveRoom(roomId);
          final activeId = ref.read(activeRoomIdProvider);
          if (activeId == roomId) {
            ref.read(activeRoomIdProvider.notifier).setActive(null);
          }
          break;
        case 'dissolve':
          await ref
              .read(roomListServiceProvider.notifier)
              .dissolveGroup(roomId);
          final activeId = ref.read(activeRoomIdProvider);
          if (activeId == roomId) {
            ref.read(activeRoomIdProvider.notifier).setActive(null);
          }
          break;
      }
    });
  }
}

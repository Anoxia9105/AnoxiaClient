import 'package:anoxia/common/utils/DateUtil.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/common/widgets/VibratingBadge.dart';
import 'package:anoxia/features/chat/presentation/widgets/create_chat_dialog_widget.dart';
import 'package:anoxia/features/contact/presentation/pages/add_friend_page.dart';
import 'package:anoxia/framework/domain/ChatRoomMemberVO.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/room/pinned_rooms_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_page.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 聊天房间列表页面
///
/// 展示所有聊天会话，支持：
/// - 搜索过滤
/// - 置顶/取消置顶
/// - 标记已读
/// - 删除/解散房间
/// - 下拉刷新
class ChatRoomList extends ConsumerStatefulWidget {
  const ChatRoomList({super.key});

  @override
  ConsumerState createState() => _ChatRoomListState();
}

class _ChatRoomListState extends ConsumerState<ChatRoomList> {
  /// 搜索框控制器
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
                    // 有搜索内容时显示清除按钮
                    suffixIcon: ref.watch(roomSearchQueryProvider).isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(roomSearchQueryProvider.notifier)
                                  .update('');
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
            // 添加房间/好友按钮
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedLayerAdd),
                  onPressed: () => _showAddRoomDetail(context),
                );
              },
            ),
          ],
        ),
      ),
      // 异步状态处理
      body: roomListAsync.when(
        data: (rooms) => _buildRoomList(context, ref),
        loading: () => const _ChatRoomListSkeleton(),
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
            constraints: const BoxConstraints(maxWidth: 220, maxHeight: 600),
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
                          return const CreateChatDialogWidget();
                        },
                      );
                      close?.call();
                    },
                    label: Text('chat_create_group'.tr()),
                    icon: const HugeIcon(
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
                      _showAddFriendDialog(context, ref);
                    },
                    label: Text('chat_add_friend'.tr()),
                    icon: const HugeIcon(
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

  Widget _buildRoomList(BuildContext context, WidgetRef ref) {
    final filteredRooms = ref.watch(filteredRoomListProvider);
    final query = ref.watch(roomSearchQueryProvider);
    final pinnedIds = ref.watch(pinnedRoomsProvider);

    if (filteredRooms.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(roomListServiceProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
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
              ),
            ),
          ],
        ),
      );
    }

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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sortedRooms.length,
        itemBuilder: (context, index) {
          return _RoomItem(room: sortedRooms[index]);
        },
        clipBehavior: Clip.hardEdge,
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context, WidgetRef ref) {
    final isDesktop = DeviceUtil.isRealDesktop();
    final dialogWidth = isDesktop ? 900.0 : 400.0;
    final dialogHeight = isDesktop ? 700.0 : 600.0;

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: const AddFriendPage(),
          ),
        );
      },
    );
  }
}

class _ChatRoomListSkeleton extends StatelessWidget {
  const _ChatRoomListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemBuilder: (context, index) => _ChatRoomSkeletonItem(index: index),
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemCount: 9,
    );
  }
}

class _ChatRoomSkeletonItem extends StatelessWidget {
  final int index;

  const _ChatRoomSkeletonItem({required this.index});

  @override
  Widget build(BuildContext context) {
    final titleWidth = 82.0 + (index % 3) * 26;
    final subtitleWidth = 130.0 + (index % 4) * 28;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: [
          const Stack(
            clipBehavior: Clip.none,
            children: [
              SkeletonBox(width: 40, height: 40, radius: 8),
              Positioned(
                right: -1,
                bottom: -1,
                child: SkeletonBox(width: 11, height: 11, circle: true),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: titleWidth, height: 13),
                const SizedBox(height: 9),
                SkeletonLine(width: subtitleWidth, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonLine(width: 38, height: 10),
              SizedBox(height: 10),
              SkeletonBox(width: 12, height: 12, circle: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomItem extends ConsumerWidget {
  final ChatRoomVO room;

  const _RoomItem({required this.room});

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
        if (context.mounted) {
          _showContextMenu(context, ref, details.globalPosition, isPinned);
        }
      },
      onLongPressStart: (details) async {
        if (roomId == null) return;
        await ref.read(roomMemberServiceProvider.notifier).syncMembers(roomId);
        if (context.mounted) {
          _showContextMenu(context, ref, details.globalPosition, isPinned);
        }
      },
      child: ListTile(
        onTap: () {
          if (room.roomId != null) {
            ref.read(activeRoomIdProvider.notifier).setActive(room.roomId!);

            if (DeviceUtil.isRealMobile()) {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ChatRoomDetail()));
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
            _RoomTypeTag(isSingle: isSingle),
          ],
        ),
        subtitle: Text(
          room.lastMessage?.content ?? '',
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
              VibratingBadge(count: room.unreadCount ?? 0),
            ],
          ),
        ),
      ),
    );
  }

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

    final members = ref.read(roomMembersProvider(roomId));

    final ChatRoomMemberVO? me = members
        .where((m) => m.userId == currentUserId)
        .firstOrNull;
    final canDissolve = me?.roleId == 0;

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

class _RoomTypeTag extends StatelessWidget {
  final bool isSingle;

  const _RoomTypeTag({required this.isSingle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isSingle
        ? colorScheme.tertiaryContainer.withValues(alpha: 0.7)
        : colorScheme.primaryContainer.withValues(alpha: 0.8);
    final fgColor = isSingle
        ? colorScheme.onTertiaryContainer
        : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSingle ? Icons.person_outline : Icons.groups_2_outlined,
            size: 11,
            color: fgColor,
          ),
          const SizedBox(width: 2),
          Text(
            isSingle ? 'chat_type_private'.tr() : 'chat_type_group'.tr(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}

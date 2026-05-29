import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_page.dart';
import 'package:anoxia/features/contact/presentation/widgets/group_room_widgets.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../framework/provider/chat/room/room_member_service.dart';
import '../../../../framework/provider/chat/room/room_list_service.dart';

/// 群聊列表页面
///
/// 显示用户加入的所有群聊，支持：
/// - 展示群聊列表（头像、名称、最新消息、成员数、未读数）
/// - 点击进入群聊
/// - 桌面端/移动端适配
class GroupRoomListPage extends ConsumerWidget {
  const GroupRoomListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupRoomListProvider);

    return Scaffold(
      backgroundColor: DeviceUtil.isRealDesktop()
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text('${'contact_joined_groups'.tr()} ${groups.isNotEmpty ? '(${groups.length})' : ''}')),
      body: groups.isEmpty
          ? const GroupRoomEmptyState()
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final room = groups[index];
                final roomId = room.roomId;

                if (roomId != null) {
                  // 预热成员缓存：RoomMemberService 内部会自动去重，避免重复请求。
                  ref.read(roomMemberServiceProvider.notifier).syncMembers(roomId);
                }

                final memberCount = roomId == null
                    ? 0
                    : ref.watch(roomMemberCountProvider(roomId));

                return GroupRoomTile(
                  avatar: room.roomAvatar ?? '',
                  roomName: room.roomName ?? 'group_unnamed'.tr(),
                  subtitle:
                      room.lastMessage?.content ??
                      'chat_no_messages_in_group'.tr(),
                  unreadCount: room.unreadCount ?? 0,
                  memberCount: memberCount,
                  onTap: roomId == null
                      ? null
                      : () async {
                          /// 选中聊天室，设置当前活跃房间 ID
                          ref.read(activeRoomIdProvider.notifier).setActive(roomId);
                          /// 跳转到聊天页面
                          ref.read(layoutControllerProvider.notifier).setIndex(0);

                          /// 仅在移动端导航到聊天详情页，桌面端保持当前页面不变（聊天详情在侧边栏展示）
                          if (DeviceUtil.isRealMobile()) {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatRoomDetail(roomId: roomId),
                              ),
                            );

                            if (context.mounted) {
                              ref
                                  .read(activeRoomIdProvider.notifier)
                                  .setActive(null);
                            }
                          }
                        },
                );
              },
            ),
    );
  }
}

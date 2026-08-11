import 'package:anoxia/common/utils/date_util.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/features/chat/presentation/formatters/message_preview_formatter.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_page.dart';
import 'package:anoxia/features/contact/presentation/widgets/group_room/group_room_tile.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../framework/provider/chat/room/room_member_service.dart';
import '../../../../framework/provider/chat/room/room_list_service.dart';

/// 群聊列表页面
///
/// 显示用户加入的所有群聊，支持点击进入群聊并适配桌面端/移动端。
class GroupRoomListPage extends ConsumerWidget {
  const GroupRoomListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupRoomListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '${'contact_joined_groups'.tr()} ${groups.isNotEmpty ? '(${groups.length})' : ''}',
        ),
      ),
      body: groups.isEmpty
          ? const _EmptyState()
          : AnimationLimiter(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: groups.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final room = groups[index];
                  final roomId = room.roomId;

                  if (roomId != null) {
                    // 预热成员缓存：RoomMemberService 内部会自动去重，避免重复请求。
                    ref
                        .read(roomMemberServiceProvider.notifier)
                        .syncMembers(roomId);
                  }

                  final memberCount = roomId == null
                      ? 0
                      : ref.watch(roomMemberCountProvider(roomId));

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 260),
                    child: SlideAnimation(
                      verticalOffset: 20,
                      child: FadeInAnimation(
                        child: GroupRoomTile(
                          avatar: room.roomAvatar ?? '',
                          roomName: room.roomName ?? 'group_unnamed'.tr(),
                          subtitle: MessagePreviewFormatter.format(
                            room.lastMessage,
                            fallback: 'chat_no_messages_in_group'.tr(),
                          ),
                          lastMessageAt: DateUtil.formatTime(
                            room.lastMessage?.timestamp,
                          ),
                          unreadCount: room.unreadCount ?? 0,
                          memberCount: memberCount,
                          onTap: roomId == null
                              ? null
                              : () async {
                                  ref
                                      .read(activeRoomIdProvider.notifier)
                                      .setActive(roomId);
                                  ref
                                      .read(layoutControllerProvider.notifier)
                                      .setIndex(0);

                                  if (DeviceUtil.isRealMobile()) {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ChatRoomDetail(roomId: roomId),
                                      ),
                                    );

                                    if (context.mounted) {
                                      ref
                                          .read(activeRoomIdProvider.notifier)
                                          .setActive(null);
                                    }
                                  }
                                },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/// 空状态：暂无群聊
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: 0.14),
                  cs.primary.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedUserGroup02,
              size: 42,
              color: cs.primary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'group_no_groups'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

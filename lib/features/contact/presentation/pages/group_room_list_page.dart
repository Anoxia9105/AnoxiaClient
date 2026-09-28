import 'package:anoxia/common/utils/date_util.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:anoxia/features/chat/presentation/formatters/message_preview_formatter.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/create_chat_dialog_widget.dart';
import 'package:anoxia/features/contact/presentation/widgets/group_room/group_room_tile.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../framework/provider/chat/room/room_member_service.dart';
import '../../../../framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';

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
          ? _EmptyState(
              onCreate: () {
                // 单栏（手机/平板竖屏）全屏推入建群页，双栏才弹桌面对话框。
                if (DeviceUtil.useSingleColumnPush(context)) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const CreateChatDialogWidget(asPage: true),
                    ),
                  );
                  return;
                }
                showEscClosableDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const CreateChatDialogWidget(),
                );
              },
            )
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

                                  // 单栏（手机/平板竖屏，含 Web 窄窗口）点群直接 push 聊天详情，
                                  // 返回后清空 active；双栏仅切 active，右侧即时展示。
                                  // 用 useSingleColumnPush 而非 isRealMobile，否则平板竖屏/
                                  // Web 窄屏点群只切 active 不 push，表现与聊天列表不一致。
                                  if (DeviceUtil.useSingleColumnPush(context)) {
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

/// 空状态：暂无群聊时展示引导
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(RadiusToken.xl),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.12),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedUserGroup02,
                size: 58,
                color: cs.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'group_no_groups'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: SpacingToken.xl),
            FilledButton.tonalIcon(
              onPressed: onCreate,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedChatting01,
                size: 18,
              ),
              label: Text('chat_create_group'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_settings_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_call_button_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_group_action_buttons_widget.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../framework/protocol/message/HighMessage.dart';
import '../../../../../framework/provider/chat/message/high_message_service.dart';
import '../../../../../framework/provider/chat/room/room_list_service.dart';

/// 聊天房间 AppBar 组件
///
/// 显示房间信息、通话按钮、搜索按钮、成员管理等功能
/// 实现了 [PreferredSizeWidget] 接口，可以在 Scaffold 中作为 AppBar 使用
class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final ChatRoomVO room;
  const ChatAppBar({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// 房间列表状态（用于监听房间信息变化，更新标题等）
    final roomListAsync = ref.watch(roomListServiceProvider);

    /// 当前用户信息
    final currentUser = ref.watch(authControllerProvider).value;
    // 用新的 Provider：只有当前房间成员变化才重建，不受其他房间影响
    final members = ref.watch(roomMembersProvider(room.roomId ?? ''));
    // 当前用户是否是管理员
    final isAdmin = ref.watch(
      isRoomAdminProvider((room.roomId ?? '', currentUser?.userId ?? 0)),
    );

    /// 是否有人正在输入（通过高优消息监听）
    final isTyping = ref.watch(
      highMessageServiceProvider.select(
        (state) =>
            state[room.roomId ?? '']?[HighMessageType.TYPING_STATUS]?.content ==
            'true',
      ),
    );

    return AppBar(
      actionsPadding: const EdgeInsets.all(4),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          height: 1.0,
        ),
      ),
      title: roomListAsync.when(
        data: (_) {
          if (isTyping) {
            return Text(
              'appbar_user_typing'.tr(),
              style: const TextStyle(fontSize: 16),
            );
          }
          final displayTitle = room.roomType == 1
              ? '${room.roomName} (${members.length})'
              : (room.roomName ?? 'appbar_conversation_detail'.tr());
          return Text(
            displayTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          );
        },
        loading: () => Text('appbar_connecting'.tr()),
        error: (error, stackTrace) => Text('appbar_connection_lost'.tr()),
      ),
      actions: () {
        /// 移动端暂不显示通话和成员管理按钮，放在更多菜单里
        if (DeviceUtil.isRealMobile()) {
          return [
            IconButton(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedMoreVertical),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatRoomDetailSettingsPage(room: room),
                  ),
                );
              },
            ),
          ];
        }

        return [
          /// 通话按钮（房间正常状态才显示，禁言/封禁/解散不显示）
          if (room.roomStatus == 0) ...[
            ChatCallButtonWidget(room: room), // 通话按钮组件化
            Container(
              margin: const EdgeInsets.all(4),
              child: const VerticalDivider(indent: 4, endIndent: 4),
            ),
          ],

          // 搜索按钮
          IconButton(
            tooltip: 'appbar_search_in_chat'.tr(),
            onPressed: () =>
                ref.read(roomListServiceProvider.notifier).toggleSearch(),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: 20,
            ),
          ),

          // 更多群功能组件化（添加、禁言、列表）
          if (room.roomType == 1)
            ChatGroupActionButtonsWidget(
              room: room,
              members: members,
              isAdmin: isAdmin,
              currentUserId: currentUser?.userId,
            ),
        ];
      }(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

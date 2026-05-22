import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_settings_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_call_button_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_group_action_buttons_widget.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  /// 修改为只接收 roomId
  final String roomId;

  const ChatAppBar({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 动态监听最新的房间数据
    final room = ref.watch(currentRoomProvider(roomId));

    // 2. 依然保留 roomListAsync 状态用于网络连接或基础加载状态判断
    final roomListAsync = ref.watch(roomListServiceProvider);

    // 用新的 Provider：只有当前房间成员变化才重建，不受其他房间影响
    final members = ref.watch(roomMembersProvider(roomId));

    /// 是否有人正在输入（通过高优消息监听）
    final isTyping = ref.watch(
      highMessageServiceProvider.select(
        (state) =>
            state[roomId]?[HighMessageType.TYPING_STATUS]?.content == 'true',
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
      // 3. 将异步状态和实体解包结合处理
      title: roomListAsync.when(
        data: (_) {
          if (room == null) return const SizedBox.shrink();

          if (isTyping) {
            return Text(
              'appbar_user_typing'.tr(),
              style: const TextStyle(fontSize: 16),
            );
          }

          // 这里使用的是从 Provider 实时拿到的 room
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
        // 如果房间尚未准备好，不展示右侧动作栏
        if (room == null) return <Widget>[];

        /// 移动端暂不显示通话和成员管理按钮，放在更多菜单里
        if (DeviceUtil.isRealMobile()) {
          return [
            IconButton(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedMoreVertical),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatRoomDetailSettingsPage(roomId: roomId),
                  ),
                );
              },
            ),
          ];
        }

        return [
          /// 通话按钮（房间正常状态才显示，禁言/封禁/解散不显示）
          if (room.roomStatus == 0) ...[
            ChatCallButtonWidget(roomId: roomId), // 通话按钮组件化
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
          if (room.roomType == 1) ChatGroupActionButtonsWidget(roomId: roomId),
        ];
      }(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/breathing_dot.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_settings_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_call_button_widget.dart';
import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../framework/protocol/message/high_message.dart';
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
    final contactMap = ref.watch(contactListServiceProvider).value;

    /// 是否有人正在输入（通过高优消息监听）
    final isTyping = ref.watch(
      highMessageServiceProvider.select(
        (state) =>
            state[roomId]?[HighMessageType.TYPING_STATUS]?.content == 'true',
      ),
    );

    return AppBar(
      centerTitle: DeviceUtil.isRealMobile(),
      actionsPadding: const EdgeInsets.all(4),
      title: roomListAsync.when(
        data: (_) {
          if (room == null) return const SizedBox.shrink();

          final peerContact = room.peerId == null
              ? null
              : contactMap?[room.peerId];
          final peerDisplayName = peerContact?.remark?.trim().isNotEmpty == true
              ? peerContact!.remark!.trim()
              : peerContact?.nickName?.trim();
          final displayTitle = room.roomType == 1
              ? '${room.roomName} (${members.length})'
              : (peerDisplayName?.isNotEmpty == true
                    ? peerDisplayName!
                    : (room.roomName ?? 'appbar_conversation_detail'.tr()));

          // 手机端标题保持简洁：只显示名字；对方输入时用输入状态替换名字。
          if (DeviceUtil.isRealMobile()) {
            return Text(
              room.roomType == 0 && isTyping
                  ? 'appbar_user_typing'.tr()
                  : displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                // 房间头像
                AvatarWidget(
                  url: room.roomAvatar,
                  name: displayTitle,
                  size: 40,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 显示房间名称或群组名称
                      Text(
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // 显示在线人数或输入状态
                      _buildTitleOrTypingStatus(
                        context,
                        room,
                        members,
                        isTyping,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
              mouseCursor: SystemMouseCursors.click,
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
          ],

          // 更多按钮
          IconButton(
            mouseCursor: SystemMouseCursors.click,
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedMoreVertical),
            onPressed: () {
              ref.read(chatRightPanelVisibleProvider.notifier).state = !ref
                  .read(chatRightPanelVisibleProvider);
            },
          ),
        ];
      }(),
    );
  }

  /// 构建标题栏下方的状态信息：单聊显示“对方正在输入...”，群聊显示在线人数
  Widget _buildTitleOrTypingStatus(
    BuildContext context,
    ChatRoomVO room,
    List<ChatRoomMemberVO> members,
    bool isTyping,
  ) {
    // 单聊且正在输入 → 显示“对方正在输入...”
    if (room.roomType == 0 && isTyping) {
      return Container(
        height: 20,
        alignment: Alignment.centerLeft,
        child: Text(
          'appbar_user_typing'.tr(),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      );
    }

    // 群聊 → 显示在线人数
    if (room.roomType == 1) {
      final onlineCount = members.where((m) => m.onlineStatus == true).length;
      final totalCount = members.length;
      return SizedBox(
        height: 20,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const BreathingDot(),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$onlineCount人在线 / $totalCount位成员',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    }

    // 私聊且没有输入状态 → 空占位，保持高度
    return const SizedBox(height: 20);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

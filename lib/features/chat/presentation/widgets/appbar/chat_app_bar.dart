import 'package:anoxia/common/utils/device_util.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/online_status_pill.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_settings_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_call_button_widget.dart';
import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../framework/protocol/message/high_message.dart';
import '../../../../../framework/provider/chat/message/high_message_service.dart';
import '../../../../../framework/provider/chat/room/room_list_service.dart';
import '../../../../../framework/provider/chat/chat_focus_mode_controller.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

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

    // 平板竖屏与手机一致走单栏推入：标题居中、只显示名字（无头像）、
    // 隐藏专注按钮，右侧更多走 push 详情页而非切换右侧面板。
    // 用 useSingleColumnPush 而非 isMobile，否则平板竖屏会误入桌面的
    // 双栏分支：点“房间详细”只翻 chatRightPanelVisibleProvider，
    // 而单栏详情页根本没有右侧面板，表现为“点击没有反应”。
    final bool isSingleColumn = DeviceUtil.useSingleColumnPush(context);

    return AppBar(
      centerTitle: isSingleColumn,
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
          final displayTitle = room.isOfficial
              ? 'official_room_name'.tr()
              : room.roomType == 1
              ? (room.roomName ?? 'appbar_conversation_detail'.tr())
              : (peerDisplayName?.isNotEmpty == true
                    ? peerDisplayName!
                    : (room.roomName ?? 'appbar_conversation_detail'.tr()));

          // 单栏（手机/平板竖屏）标题保持简洁：隐藏头像、只居中显示名字；
          // 群聊标题聚合人数（群名 · N），对方输入时用输入状态替换名字，与手机端保持一致。
          if (isSingleColumn) {
            final singleColumnTitle =
                room.roomType == 0 && isTyping
                    ? 'appbar_user_typing'.tr()
                    : room.roomType == 1
                    ? '$displayTitle · ${members.length}'
                    : displayTitle;
            return Text(
              singleColumnTitle,
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
                if (room.isOfficial)
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(RadiusToken.lg),
                    ),
                    child: Assets.images.appIconPng.image(
                      fit: BoxFit.contain,
                      semanticLabel: displayTitle,
                    ),
                  )
                else
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

        // 官方帮助页所有内容均在当前屏展示，不提供聊天详情或更多操作。
        if (room.isOfficial && isSingleColumn) {
          return <Widget>[];
        }

        /// 单栏（手机/平板竖屏）暂不显示专注/通话按钮，详情走 push，放在更多菜单里
        if (isSingleColumn) {
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
          IconButton(
            mouseCursor: SystemMouseCursors.click,
            tooltip: ref.watch(chatFocusModeProvider)
                ? 'chat_focus_exit'.tr()
                : 'chat_focus_enter'.tr(),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedChangeScreenMode,
              size: 20,
            ),
            onPressed: ref.read(chatFocusModeProvider.notifier).toggle,
          ),
          /// 通话按钮（房间正常状态才显示，官方虚拟房间 / 禁言 / 封禁不显示）
          if (room.roomStatus == 0 && !room.isOfficial) ...[
            ChatCallButtonWidget(roomId: roomId), // 通话按钮组件化
          ],

          // 更多按钮
          if (!room.isOfficial)
            IconButton(
              mouseCursor: SystemMouseCursors.click,
              tooltip: 'appbar_conversation_detail_tooltip'.tr(),
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

  /// 构建标题栏下方的状态信息：单聊显示“对方正在输入...”，群聊显示在线胶囊 + 成员总数
  Widget _buildTitleOrTypingStatus(
    BuildContext context,
    ChatRoomVO room,
    List<ChatRoomMemberVO> members,
    bool isTyping,
  ) {
    if (room.isOfficial) {
      return SizedBox(
        height: 20,
        child: Text(
          'official_room_list_hint'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // 单聊且正在输入 → 显示“对方正在输入...”
    if (room.roomType == 0 && isTyping) {
      return Container(
        height: 20,
        alignment: Alignment.centerLeft,
        child: Text(
          'appbar_user_typing'.tr(),
          style: Theme.of(context).textTheme.bodySmall!.copyWith( color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    // 群聊 → 在线数穿胶囊徽章强调，总数灰字弱化，不再用斜杠双统计
    if (room.roomType == 1) {
      final onlineCount = members.where((m) => m.onlineStatus == true).length;
      final totalCount = members.length;
      return SizedBox(
        height: 20,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            OnlineStatusPill(
              text: 'common_online_count'.tr(
                args: [onlineCount.toString()],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'chat_member_total'.tr(args: [totalCount.toString()]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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

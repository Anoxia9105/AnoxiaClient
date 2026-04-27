import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/domain/ChatRoomMemberVO.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/call/call_status_provider.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../framework/protocol/message/HighMessage.dart';
import '../../../../framework/provider/chat/message/high_message_service.dart';
import '../../../../framework/provider/chat/room/room_list_service.dart';
import '../../../../framework/provider/theme/theme_controller.dart';
import 'AddMemberDialogWidget.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ChatAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeRoomIdProvider);
    final roomListAsync = ref.watch(roomListServiceProvider);
    final currentRoom = ref.read(activeRoomProvider);
    final currentUser = ref.watch(authControllerProvider).value;
    final currentRoomId = currentRoom?.roomId ?? '';
  final callWindow = ref.watch(callWindowControllerProvider);

  final callStatus = ref.watch(roomCallStatusProvider(currentRoomId));
  final isCallingNow = callStatus.calling;

  // 首次进入当前房间时拉一次状态（无轮询）
  ref.read(callStatusControllerProvider.notifier).ensureLoaded(currentRoomId);

  final callActionLabel = callWindow != null
    ? '通话中'
    : (isCallingNow ? '加入通话' : '发起通话');

  final callActionIcon = callWindow != null
    ? HugeIcons.strokeRoundedCallEnd03
    : (isCallingNow
      ? HugeIcons.strokeRoundedCallRinging03
      : HugeIcons.strokeRoundedCall02);

  final callActionColor = callWindow != null
    ? Colors.orangeAccent
    : (isCallingNow ? Theme.of(context).colorScheme.primary : null);

    // 用新的 Provider：只有当前房间成员变化才重建，不受其他房间影响
    final members = ref.watch(roomMembersProvider(activeId ?? ''));

    // 当前用户是否是管理员（用 isRoomAdminProvider，语义清晰）
    final isAdmin = ref.watch(
      isRoomAdminProvider((activeId ?? '', currentUser?.userId ?? 0)),
    );

    final isTyping = ref.watch(
      highMessageServiceProvider.select(
        (state) =>
            state[activeId]?[HighMessageType.TYPING_STATUS]?.content == "true",
      ),
    );

    // 给自己的昵称加上"(我)"后缀，只在展示时处理，不改原始数据
    final displayMembers = members.map((m) {
      if (m.userId == currentUser?.userId) {
        return m.copyWith(
          nickName: "${m.nickName ?? 'appbar_unknown_user'.tr()} ${'chat_me_suffix'.tr()}",
        );
      }
      return m;
    }).toList();

    return AppBar(
      actionsPadding: EdgeInsets.all(4),
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
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            );
          }
          return Text(
            currentRoom?.roomName ?? 'appbar_conversation_detail'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          );
        },
        loading: () => Text('appbar_connecting'.tr()),
    error: (error, stackTrace) => Text('appbar_connection_lost'.tr()),
      ),
      actions: [
        // 发起通话按钮（房间未解散才显示）
        if (currentRoom?.roomStatus != 3)
          IconButton(
            tooltip: callActionLabel,
            onPressed: () {
              ref.read(callWindowControllerProvider.notifier).openCallWindow(
                title: currentRoom?.roomName ?? '',
                themeIndex: ref.read(themeIndexProvider),
                roomId: currentRoom?.roomId ?? '',
              );
            },
            icon: HugeIcon(
              icon: callActionIcon,
              size: 20,
              color: callActionColor,
            ),
          ),

        if (currentRoom?.roomStatus != 3)
          Container(
            margin: EdgeInsets.all(4),
            child: VerticalDivider(indent: 4, endIndent: 4),
          ),

        // 搜索按钮
        IconButton(
          tooltip: 'appbar_search_in_chat'.tr(),
          onPressed: () =>
              ref.read(roomListServiceProvider.notifier).toggleSearch(),
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 20),
        ),

        // 添加成员按钮（群聊 + 未解散）
        if (currentRoom != null &&
            currentRoom.roomType == 1 &&
            currentRoom.roomStatus != 3)
          IconButton(
            tooltip: 'appbar_add_member'.tr(),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddMemberDialogWidget(
                  roomId: currentRoom.roomId!,
                  roomName: currentRoom.roomName!,
                ),
              );
            },
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedAddTeam,
              size: 20,
            ),
          ),

        // 全体禁言按钮（群聊 + 管理员 + 未解散）
        if (currentRoom != null &&
            currentRoom.roomType == 1 &&
            currentRoom.roomStatus != 3 &&
            isAdmin)
          _MuteButton(
            isMuted: currentRoom.roomStatus == 1,
            onTap: () => _handleMuteRoom(
              context,
              ref,
              currentRoom.roomId ?? '',
              currentRoom.roomStatus != 1,
            ),
          ),

        // 成员列表按钮（未解散才显示）
        if (currentRoom?.roomStatus != 3)
          Builder(
            builder: (context) => _MemberListButton(
              members: displayMembers,
              currentUserId: currentUser?.userId,
              isAdmin: isAdmin,
              roomId: currentRoom?.roomId ?? '',
              onKick: (m) => _handleKickMember(
                context,
                ref,
                currentRoom?.roomId ?? '',
                m.userId ?? 0,
                m.nickName ?? 'chat_unknown_user'.tr(),
              ),
            ),
          ),
      ],
    );
  }

  /// 踢出成员确认弹窗
  void _handleKickMember(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    int targetUserId,
    String targetUserName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('chat_confirm_kick'.tr()),
        content: Text('chat_confirm_kick_content'.tr(args: [targetUserName])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('dialog_cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final cancelLoading = BotToast.showLoading();
              try {
                final success = await ref
                    .read(roomMemberServiceProvider.notifier)
                    .kickMember(roomId, targetUserId);
                cancelLoading();
                BotToast.showText(
                  text: success
                      ? 'chat_kick_success'.tr()
                      : 'chat_kick_failed'.tr(),
                );
              } catch (e) {
                cancelLoading();
                BotToast.showText(
                  text: 'chat_operation_failed'.tr(args: [e.toString()]),
                );
              }
            },
            child: Text(
              'chat_confirm_btn'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  /// 全体禁言/解除禁言确认弹窗
  void _handleMuteRoom(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    bool isMute,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isMute ? 'chat_mute_all'.tr() : 'chat_unmute_all'.tr()),
        content: Text(
          isMute ? 'chat_mute_confirm'.tr() : 'chat_unmute_confirm'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('dialog_cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final cancelLoading = BotToast.showLoading();
              try {
                final success = await ref
                    .read(roomListServiceProvider.notifier)
                    .muteRoom(roomId, isMute);
                cancelLoading();
                BotToast.showText(
                  text: success
                      ? (isMute
                          ? 'chat_mute_success'.tr()
                          : 'chat_unmute_success'.tr())
                      : 'chat_operation_retry_failed'.tr(),
                );
              } catch (e) {
                cancelLoading();
                BotToast.showText(
                  text: 'chat_operation_failed'.tr(args: [e.toString()]),
                );
              }
            },
            child: Text(
              'chat_confirm_btn'.tr(),
              style: TextStyle(
                color: isMute
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ──────────────────────────────────────────
// 抽离子组件：禁言按钮
// 避免在 AppBar.actions 里嵌套过多 Builder
// ──────────────────────────────────────────

class _MuteButton extends StatelessWidget {
  final bool isMuted;
  final VoidCallback onTap;

  const _MuteButton({required this.isMuted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isMuted ? 'chat_unmute_tooltip'.tr() : 'chat_mute_tooltip'.tr(),
      onPressed: onTap,
      icon: HugeIcon(
        icon: isMuted
            ? HugeIcons.strokeRoundedVolumeMute02
            : HugeIcons.strokeRoundedVolumeOff,
        size: 20,
        color: isMuted
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

// ──────────────────────────────────────────
// 抽离子组件：成员列表按钮 + 弹出面板
// ──────────────────────────────────────────

class _MemberListButton extends StatelessWidget {
  final List<ChatRoomMemberVO> members;
  final int? currentUserId;
  final bool isAdmin;
  final String roomId;
  final void Function(ChatRoomMemberVO member) onKick;

  const _MemberListButton({
    required this.members,
    required this.currentUserId,
    required this.isAdmin,
    required this.roomId,
    required this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'appbar_member_list'.tr(),
      child: InkWell(
        onTap: () => Toast.showWidget(
          context,
          child: Material(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              width: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      '${'appbar_member_list'.tr()} (${members.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 1),

                  // 成员列表
                  Flexible(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: members.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 56),
                      itemBuilder: (context, index) {
                        final m = members[index];
                        return ListTile(
                          dense: true,
                          leading: AvatarWidget(
                            url: m.avatar,
                            name: m.nickName,
                            size: 30,
                            status: (m.onlineStatus ?? false)
                                ? AvatarStatus.online
                                : AvatarStatus.offline,
                          ),
                          title: Text(
                            m.nickName ?? 'chat_unknown_user'.tr(),
                          ),
                          trailing: _buildTrailing(context, m),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          direction: PreferDirection.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedUserMultiple02,
                size: 18,
              ),
              Text("${members.length}"),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建每行右侧的操作区域
  ///   - 管理员：显示"管理员"标签
  ///   - 我是管理员 且 当前行不是我：显示踢出按钮
  ///   - 其他情况：空
  Widget _buildTrailing(BuildContext context, ChatRoomMemberVO m) {
    // 当前行是管理员，显示标签
    if (m.roleId == 0) {
      return Text(
        'chat_admin'.tr(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    // 我是管理员 且 当前行不是我，显示踢出按钮
    if (isAdmin && m.userId != currentUserId) {
      return IconButton(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedUserRoadside,
          size: 18,
        ),
        tooltip: 'chat_kick_member'.tr(),
        onPressed: () => onKick(m),
      );
    }

    return const SizedBox.shrink();
  }
}
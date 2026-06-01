import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/chat/presentation/widgets/add_member_dialog_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_bar_handlers.dart';
import 'package:anoxia/framework/domain/ChatRoomMemberVO.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 群聊操作按钮组组件
///
/// 显示在群聊房间 AppBar 中的操作按钮集合，包括：
/// - 添加成员按钮
/// - 全体禁言/解除禁言按钮（仅管理员可见）
/// - 成员列表按钮（显示成员数量和详情）
///
/// 当房间状态为已解散（2）或已冻结（3）时，不显示任何操作按钮
class ChatGroupActionButtonsWidget extends ConsumerWidget {
  /// 当前聊天房间 ID
  final String roomId;

  const ChatGroupActionButtonsWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 提取房间对象（如果 roomListServiceProvider 是 AsyncValue，这里的 currentRoom 也会继承其状态）
    final room = ref.watch(currentRoomProvider(roomId));
    if (room == null) return const SizedBox.shrink();

    // 2. 房间状态为 2（已解散）或 3（已冻结）时，不显示任何操作按钮
    final isDisabledStatus = room.roomStatus == 2 || room.roomStatus == 3;
    if (isDisabledStatus) return const SizedBox.shrink();

    // 3. 提取当前登录用户的 ID
    final currentUser = ref.watch(authControllerProvider).value;
    final currentUserId = currentUser?.userId;

    // 4. 获取成员列表及当前用户权限
    final members = ref.watch(roomMembersProvider(roomId));
    final isAdmin = ref.watch(
      isRoomAdminProvider((roomId, currentUserId ?? 0)),
    );

    // 为当前用户添加"我"的后缀标识
    final displayMembers = members.map((m) {
      return m.userId == currentUserId
          ? m.copyWith(
              nickName:
                  '${m.nickName ?? 'appbar_unknown_user'.tr()} ${'chat_me_suffix'.tr()}',
            )
          : m;
    }).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 添加成员按钮
        IconButton(
          tooltip: 'appbar_add_member'.tr(),
          onPressed: () => showDialog(
            context: context,
            builder: (context) => AddMemberDialogWidget(
              roomId: room.roomId!,
              roomName: room.roomName!,
            ),
          ),
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedAddTeam, size: 20),
        ),
        // 全体禁言按钮（仅管理员可见）
        if (isAdmin)
          _MuteButton(
            isMuted: room.roomStatus == 1,
            onTap: () => ChatBarHandlers.showMuteRoomDialog(
              context,
              ref,
              room.roomId ?? '',
              room.roomStatus != 1,
            ),
          ),
        // 成员列表按钮
        _MemberListButton(
          members: displayMembers,
          currentUserId: currentUserId,
          isAdmin: isAdmin,
          roomId: room.roomId ?? '',
          onKick: (ChatRoomMemberVO member) =>
              ChatBarHandlers.showKickMemberDialog(
                context,
                ref,
                room.roomId ?? '',
                member,
              ),
        ),
      ],
    );
  }
}

/// 禁言/解除禁言按钮组件
class _MuteButton extends StatelessWidget {
  final bool isMuted;
  final VoidCallback onTap;

  const _MuteButton({required this.isMuted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: isMuted ? 'chat_unmute_tooltip'.tr() : 'chat_mute_tooltip'.tr(),
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: isMuted
            ? cs.primaryContainer.withValues(alpha: 0.75)
            : cs.errorContainer.withValues(alpha: 0.65),
        side: BorderSide(
          color: isMuted
              ? cs.primary.withValues(alpha: 0.35)
              : cs.error.withValues(alpha: 0.35),
          width: 0.8,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: HugeIcon(
        icon: isMuted
            ? HugeIcons.strokeRoundedVolumeHigh
            : HugeIcons.strokeRoundedVolumeMute02,
        size: 20,
        color: isMuted ? cs.primary : cs.error,
      ),
    );
  }
}

/// 成员列表按钮及弹出面板组件
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
                          title: Text(m.nickName ?? 'chat_unknown_user'.tr()),
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
              const SizedBox(width: 4),
              Text('${members.length}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, ChatRoomMemberVO m) {
    if (m.roleId == 0) {
      return Text(
        'chat_admin'.tr(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

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

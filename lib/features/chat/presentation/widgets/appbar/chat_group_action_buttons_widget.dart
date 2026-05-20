import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_bar_handlers.dart';
import 'package:anoxia/framework/domain/ChatRoomMemberVO.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class ChatGroupActionButtonsWidget extends ConsumerWidget {
  final ChatRoomVO room;
  final List<ChatRoomMemberVO> members;
  final bool isAdmin;
  final int? currentUserId;
  const ChatGroupActionButtonsWidget({
    super.key,
    required this.room,
    required this.members,
    required this.isAdmin,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// 根据房间状态决定是否显示操作按钮
    final isDisabledStatus = room.roomStatus == 2 || room.roomStatus == 3;

    /// 房间状态为 2（已解散）或 3（已冻结）时，不显示任何操作按钮
    if (isDisabledStatus) return const SizedBox.shrink();

    // 格式化处理“我”的后缀
    final displayMembers = members
        .map(
          (m) => m.userId == currentUserId
              ? m.copyWith(
                  nickName:
                      '${m.nickName ?? 'appbar_unknown_user'.tr()} ${'chat_me_suffix'.tr()}',
                )
              : m,
        )
        .toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 添加成员
        IconButton(
          tooltip: 'appbar_add_member'.tr(),
          onPressed: () => ChatBarHandlers.showAddMemberDialog(context, room),
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedAddTeam, size: 20),
        ),
        // 2. 全体禁言
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
        // 3. 成员列表
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
///
/// 避免在 AppBar.actions 里嵌套过多 Builder
class _MuteButton extends StatelessWidget {
  /// 是否已禁言
  final bool isMuted;

  /// 点击回调
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

/// 成员列表按钮 + 弹出面板组件
class _MemberListButton extends StatelessWidget {
  /// 房间成员列表
  final List<ChatRoomMemberVO> members;

  /// 当前用户 ID
  final int? currentUserId;

  /// 当前用户是否为管理员
  final bool isAdmin;

  /// 房间 ID
  final String roomId;

  /// 踢出成员回调函数
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
              Text('${members.length}'),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建每行右侧的操作区域
  ///
  /// - 管理员：显示"管理员"标签
  /// - 我是管理员且当前行不是我：显示踢出按钮
  /// - 其他情况：空
  ///
  /// [context] 上下文
  /// [m] 成员对象
  /// 返回 操作区域 Widget
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

import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 内部隔离组件：群成员头像网格，防止成员列表更新时触发整个 Settings 树重构
///
/// - 宽面板（移动端整页）5 列，窄面板（桌面 320/280 右栏）4 列
/// - 群聊展示前 [maxDisplayMembers] 个成员 +「添加成员」入口；
///   超出部分走卡片底部「查看全部成员」入口
/// - 单聊仅展示对方一个格子，无添加入口
class MemberListSection extends ConsumerWidget {
  final String roomId;
  final bool isGroup;
  final VoidCallback? onAddMemberTap;
  final void Function(ChatRoomMemberVO member)? onMemberTap;

  /// 群聊时最多展示的成员格数，超过部分通过「查看全部成员」查看
  static const int maxDisplayMembers = 8;

  const MemberListSection({
    super.key,
    required this.roomId,
    required this.isGroup,
    this.onAddMemberTap,
    this.onMemberTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(roomMembersProvider(roomId));

    final displayCount = isGroup
        ? (members.length > maxDisplayMembers
            ? maxDisplayMembers
            : members.length)
        : members.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 桌面右面板（320/280）4 列，移动端整页 5 列
        final columns = constraints.maxWidth > 340 ? 5 : 4;
        final showAdd = isGroup && onAddMemberTap != null;
        final itemCount = displayCount + (showAdd ? 1 : 0);

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 11,
            crossAxisSpacing: 6,
            // 头像 46 + 间距 6 + 两行以内昵称
            mainAxisExtent: 74,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index < displayCount) {
              return _buildMemberCell(context, members[index]);
            }
            return _buildAddCell(context);
          },
        );
      },
    );
  }

  /// 成员格：头像（右下角在线状态点）+ 昵称
  Widget _buildMemberCell(BuildContext context, ChatRoomMemberVO member) {
    final isOnline = member.onlineStatus == true;
    final displayName = member.nickName?.trim().isNotEmpty == true
        ? member.nickName!.trim()
        : 'chat_unknown_user'.tr();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onMemberTap == null ? null : () => onMemberTap!(member),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarWidget(
            url: member.avatar,
            name: displayName,
            size: 46,
            borderRadius: RadiusToken.lg,
            status: isOnline ? AvatarStatus.online : AvatarStatus.offline,
          ),
          const SizedBox(height: 6),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 末尾「添加成员」入口格
  Widget _buildAddCell(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onAddMemberTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(RadiusToken.lg),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            alignment: Alignment.center,
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedAddSquare,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'member_add_title'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

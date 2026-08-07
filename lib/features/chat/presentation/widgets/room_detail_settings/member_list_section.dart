import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/breathing_dot.dart';
import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 内部隔离组件：群成员行式列表区块，防止成员列表数据更新时触发整个 Settings 树重构
///
/// - 顶部摘要：X人在线 / Y位成员
/// - 群聊最多展示 [maxDisplayRows] 个成员行，末尾为「添加成员」入口；
///   超出上限的成员通过详情页「查看全部成员」入口查看
/// - 单聊仅展示对方一行，无摘要与添加入口
class MemberListSection extends ConsumerWidget {
  final String roomId;
  final bool isGroup;
  final VoidCallback? onAddMemberTap;
  final void Function(ChatRoomMemberVO member)? onMemberTap;

  /// 群聊时最多展示的成员行数，超过部分通过「查看全部成员」查看
  static const int maxDisplayRows = 8;

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
        ? (members.length > maxDisplayRows ? maxDisplayRows : members.length)
        : members.length;
    final onlineCount = members.where((m) => m.onlineStatus == true).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isGroup)
            _buildSummaryRow(context, onlineCount, members.length),
          for (var i = 0; i < displayCount; i++) _buildMemberRow(context, members[i]),
          if (isGroup) _buildAddMemberRow(context),
        ],
      ),
    );
  }

  /// 顶部摘要：X人在线 / Y位成员
  Widget _buildSummaryRow(
    BuildContext context,
    int onlineCount,
    int totalCount,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 2),
      child: Row(
        children: [
          const BreathingDot(),
          const SizedBox(width: 6),
          Text(
            'chat_member_status_summary'.tr(
              args: [onlineCount.toString(), totalCount.toString()],
            ),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 成员行：头像（右下角在线状态点）+ 昵称 + 在线/离线副标题 + 右箭头
  Widget _buildMemberRow(BuildContext context, ChatRoomMemberVO member) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOnline = member.onlineStatus == true;
    final displayName = member.nickName?.trim().isNotEmpty == true
        ? member.nickName!.trim()
        : 'chat_unknown_user'.tr();

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      contentPadding: EdgeInsets.zero,
      leading: AvatarWidget(
        url: member.avatar,
        name: displayName,
        size: 40,
        status: isOnline ? AvatarStatus.online : AvatarStatus.offline,
      ),
      title: Text(
        displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        isOnline ? 'contact_online'.tr() : 'contact_offline'.tr(),
        style: TextStyle(
          fontSize: 12,
          color: isOnline ? Colors.green : colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: colorScheme.outline,
      ),
      onTap: onMemberTap == null ? null : () => onMemberTap!(member),
    );
  }

  /// 末尾「添加成员」入口行
  Widget _buildAddMemberRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedAddSquare,
          color: colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
      title: Text(
        'member_add_title'.tr(),
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: colorScheme.outline,
      ),
      onTap: onAddMemberTap,
    );
  }
}

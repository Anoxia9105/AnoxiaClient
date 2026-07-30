import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 内部隔离组件：群成员网格区块，防止成员列表数据更新时触发整个 Settings 树重构
class MemberGridSection extends ConsumerWidget {
  final String roomId;
  final bool isGroup;
  final VoidCallback? onAddMemberTap;
  final void Function(ChatRoomMemberVO member)? onMemberTap;

  const MemberGridSection({
    super.key,
    required this.roomId,
    required this.isGroup,
    this.onAddMemberTap,
    this.onMemberTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final members = ref.watch(roomMembersProvider(roomId));

    final maxGridItems = isGroup ? 20 : 1;
    final displayCount = (members.length > (maxGridItems - 1) && isGroup)
        ? (maxGridItems - 1)
        : members.length;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: isGroup ? (displayCount + 1) : displayCount,
        itemBuilder: (context, index) {
          if (isGroup && index == displayCount) {
            return _buildActionButton(
              context,
              icon: HugeIcons.strokeRoundedAddSquare,
              label: 'member_add_title'.tr(),
              onTap: onAddMemberTap ?? () {},
            );
          }

          if (index >= members.length) return const SizedBox.shrink();
          final member = members[index];
          final displayName = member.nickName?.trim().isNotEmpty == true
              ? member.nickName!.trim()
              : 'chat_unknown_user'.tr();

          return GestureDetector(
            onTap: onMemberTap == null ? null : () => onMemberTap!(member),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AvatarWidget(url: member.avatar, name: displayName, size: 36),
                const SizedBox(height: 4),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required dynamic icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      mouseCursor: SystemMouseCursors.click,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: HugeIcon(
              icon: icon,
              color: colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

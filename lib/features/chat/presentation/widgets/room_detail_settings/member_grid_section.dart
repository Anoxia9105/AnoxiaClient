import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 内部隔离组件：群成员网格区块，防止成员列表数据更新时触发整个 Settings 树重构
class MemberGridSection extends ConsumerWidget {
  final String roomId;
  final bool isGroup;

  const MemberGridSection({super.key, required this.roomId, required this.isGroup});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final members = ref.watch(roomMembersProvider(roomId));

    final maxGridItems = isGroup ? 20 : 1;
    final displayCount = (members.length > (maxGridItems - 1) && isGroup) ? (maxGridItems - 1) : members.length;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.85,
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
              onTap: () {
                // TODO: 开启联系人选择页
              },
            );
          }

          if (index >= members.length) return const SizedBox.shrink();
          final member = members[index];

          return GestureDetector(
            onTap: () {
              // TODO: 跳转用户主页
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AvatarWidget(
                  url: member.avatar,
                  name: member.nickName,
                  size: 44,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Center(
                    child: Text(
                      member.nickName ?? '?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(13),
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
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
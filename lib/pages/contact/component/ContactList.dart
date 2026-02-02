import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/VibratingBadge.dart';
import 'package:anoxia/framework/domain/ChatContactVO.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_requests_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:anoxia/pages/contact/component/widget/sortedContactGroupsWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class ContactList extends ConsumerWidget {
  const ContactList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentViewType = ref.watch(
      contactSelectionProvider.select((s) => s.viewType),
    );

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(contactListServiceProvider.notifier).refresh();
      },
      child: Column(
        children: [
          // 1. 新的朋友
          _buildFunctionTile(
            ref: ref,
            icon: HugeIcons.strokeRoundedAddTeam,
            title: "新的朋友",
            isSelected: currentViewType == ContactViewType.newFriends,
            onTap: () =>
                ref.read(contactSelectionProvider.notifier).selectNewFriends(),
            trailing: VibratingBadge(
              messageCount: ref.watch(pendingRequestCountProvider).value ?? 0,
            ),
          ),
          // 2. 加入的群聊
          _buildFunctionTile(
            ref: ref,
            icon: HugeIcons.strokeRoundedUserGroup03,
            title: "加入的群聊",
            isSelected: currentViewType == ContactViewType.groups,
            onTap: () =>
                ref.read(contactSelectionProvider.notifier).selectGroups(),
          ),
          // 联系人标题
          ListTile(
            title: const Text(
              "联系人",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(child: SortedContactGroupsWidget()),
        ],
      ),
    );
  }

  // 构建固定功能的 Tile
  Widget _buildFunctionTile({
    required WidgetRef ref,
    required List<List<dynamic>> icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(ref.context).colorScheme;
    return ListTile(
      selected: isSelected,
      selectedTileColor: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.4)
          : Colors.transparent,
      leading: HugeIcon(
        icon: icon,
        strokeWidth: 2,
        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? colorScheme.primary : null,
        ),
      ),
      onTap: onTap,
      trailing: trailing,
    );
  }
}

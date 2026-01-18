import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/VibratingBadge.dart';
import 'package:anoxia/framework/domain/ChatContactVO.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:anoxia/framework/services/contact_list_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../framework/services/contact_requests_service.dart';

class ContactList extends ConsumerWidget {
  const ContactList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(sortedContactGroupsProvider);
    // 监听当前的视图类型，用于固定项的高亮
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

          Expanded(
            child: groupsAsync.when(
              data: (groupMap) {
                final items = groupMap.entries.map((e) {
                  return AlphabetListViewItemGroup(
                    tag: e.key,
                    children: e.value
                        .map((vo) => ContactItemTile(contact: vo))
                        .toList(),
                  );
                }).toList();
                return AlphabetListView(
                  items: items,

                  options: AlphabetListViewOptions(
                    listOptions: ListOptions(
                      listHeaderBuilder: (context, tag) =>
                          _buildHeader(context, tag),
                    ),
                    overlayOptions: OverlayOptions(
                      overlayBuilder: (context, symbol) {
                        return Container(
                          alignment: Alignment.center,
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            // 使用主色调，并添加一点透明度，显得轻盈
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            symbol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),

                    // 顺便把侧边栏也稍微调优一下，保持一致
                    scrollbarOptions: ScrollbarOptions(
                      backgroundColor: Colors.transparent, // 背景透明更现代
                      padding: const EdgeInsets.only(right: 4),
                      symbolBuilder: (context, symbol, state) {
                        final isActive =
                            state == AlphabetScrollbarItemState.active;
                        return Center(
                          child: Text(
                            symbol,
                            style: TextStyle(
                              fontSize: 12,
                              color: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('加载失败: $err')),
            ),
          ),
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

  Widget _buildHeader(BuildContext context, String tag) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      width: double.infinity,
      child: Text(
        tag,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// 独立的联系人列表项
class ContactItemTile extends ConsumerWidget {
  final ChatContactVO contact;

  const ContactItemTile({super.key, required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听是否被选中：类型为 contactDetail 且 ID 匹配
    final isSelected = ref.watch(
      contactSelectionProvider.select(
        (s) =>
            s.viewType == ContactViewType.contactDetail &&
            s.selectedContact?.contactId == contact.contactId,
      ),
    );

    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.4)
          : Colors.transparent,
      child: ListTile(
        dense: true,
        selected: isSelected,
        selectedColor: colorScheme.primary,
        leading: AvatarWidget(
          url: contact.avatar,
          name: contact.nickName,
          status: contact.onlineStatus ?? false
              ? AvatarStatus.online
              : AvatarStatus.offline,
        ),
        title: Text(
          contact.nickName ?? '',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () =>
            ref.read(contactSelectionProvider.notifier).selectContact(contact),
      ),
    );
  }
}

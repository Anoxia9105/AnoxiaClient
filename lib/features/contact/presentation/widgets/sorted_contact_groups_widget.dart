import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:anoxia/framework/domain/ChatContactVO.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 按字母排序的联系人分组组件
///
/// 使用 AlphabetListView 实现字母索引功能，支持按姓氏首字母分组显示联系人
/// 键盘弹出时自动切换为普通列表以避免性能问题
class SortedContactGroupsWidget extends ConsumerWidget {
  /// 自定义联系人项构建器（可选）
  final Widget Function(ChatContactVO vo)? itemBuilder;

  /// 联系人点击回调（可选）
  final VoidCallback? onContactTap;

  const SortedContactGroupsWidget({
    super.key,
    this.itemBuilder,
    this.onContactTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(sortedContactGroupsProvider);

    return groupsAsync.when(
      data: (groupMap) {
        final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
        final normalizedEntries = groupMap.entries.where((e) {
          final tag = e.key.trim();
          return tag.isNotEmpty && e.value.isNotEmpty;
        }).toList();

        final items = normalizedEntries.map((e) {
          return AlphabetListViewItemGroup(
            tag: e.key.trim(),
            children: e.value.map((vo) {
              return itemBuilder != null
                  ? itemBuilder!(vo)
                  : ContactItemTile(contact: vo, onTap: onContactTap);
            }).toList(),
          );
        }).toList();

        if (items.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    'chat_no_conversations'.tr(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final useSafePlainList = keyboardVisible;
        if (useSafePlainList) {
          return _buildPlainGroupedList(context, normalizedEntries);
        }

        return SizedBox.expand(
          child: AlphabetListView(
            items: items,
            options: AlphabetListViewOptions(
              listOptions: ListOptions(
                listHeaderBuilder: (context, tag) => _buildHeader(context, tag),
              ),
              overlayOptions: OverlayOptions(
                overlayBuilder: (context, symbol) {
                  final safeSymbol = symbol.toString().trim().isEmpty
                      ? '#'
                      : symbol.toString();
                  return Container(
                    alignment: Alignment.center,
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
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
                      safeSymbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              scrollbarOptions: ScrollbarOptions(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.only(right: 4),
                symbolBuilder: (context, symbol, state) {
                  final safeSymbol = symbol.toString().trim().isEmpty
                      ? '#'
                      : symbol.toString();
                  final isActive = state == AlphabetScrollbarItemState.active;
                  return Center(
                    child: Text(
                      safeSymbol,
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      loading: () => const _ContactGroupsSkeleton(),
      error: (err, stack) =>
          Center(child: Text('${'contact_load_failed_with_error'.tr()}: $err')),
    );
  }

  /// 构建分组标题
  ///
  /// [context] 上下文
  /// [tag] 分组标签（字母）
  /// 返回 分组标题 Widget
  Widget _buildHeader(BuildContext context, String tag) {
    final safeTag = tag.trim().isEmpty ? '#' : tag.trim();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      width: double.infinity,
      child: Text(
        safeTag,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// 构建普通分组列表（用于键盘弹出时）
  ///
  /// [context] 上下文
  /// [entries] 分组条目列表
  /// 返回 普通分组列表 Widget
  Widget _buildPlainGroupedList(
    BuildContext context,
    List<MapEntry<String, List<ChatContactVO>>> entries,
  ) {
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, groupIndex) {
        final entry = entries[groupIndex];
        final children = entry.value.map((vo) {
          return itemBuilder != null
              ? itemBuilder!(vo)
              : ContactItemTile(contact: vo, onTap: onContactTap);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildHeader(context, entry.key), ...children],
        );
      },
    );
  }
}

/// 联系人分组列表骨架屏
///
/// 用于在联系人加载过程中显示占位内容
class _ContactGroupsSkeleton extends StatelessWidget {
  const _ContactGroupsSkeleton();

  @override
  Widget build(BuildContext context) {
    const count = 12;
    return ListView.builder(
      itemCount: count,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final showHeader = index == 0 || index == 5 || index == 9;
        final nameWidth = 90.0 + (index % 4) * 22;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: SkeletonLine(width: 16, height: 12),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListTile(
                dense: true,
                leading: const SkeletonBox(width: 40, height: 40, radius: 8),
                title: Align(
                  alignment: Alignment.centerLeft,
                  child: SkeletonLine(width: nameWidth, height: 13),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SkeletonLine(width: 72, height: 10),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 联系人项组件
///
/// 显示单个联系人的头像、昵称和在线状态
class ContactItemTile extends ConsumerWidget {
  /// 联系人对象
  final ChatContactVO contact;

  /// 点击回调（可选）
  final VoidCallback? onTap;

  const ContactItemTile({super.key, required this.contact, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        minLeadingWidth: 40,
        horizontalTitleGap: 10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        selected: isSelected,
        selectedColor: colorScheme.primary,
        leading: AvatarWidget(
          size: 34,
          url: contact.avatar,
          name: contact.nickName,
          status: contact.onlineStatus ?? false
              ? AvatarStatus.online
              : AvatarStatus.offline,
        ),
        title: Text(
          contact.remark ?? contact.nickName ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          ref.read(contactSelectionProvider.notifier).selectContact(contact);
          onTap?.call();
        },
      ),
    );
  }
}

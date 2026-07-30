import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:anoxia/features/contact/presentation/widgets/sorted_contacts/contact_alphabet_overlay.dart';
import 'package:anoxia/features/contact/presentation/widgets/sorted_contacts/contact_alphabet_symbol.dart';
import 'package:anoxia/features/contact/presentation/widgets/sorted_contacts/contact_group_header.dart';
import 'package:anoxia/features/contact/presentation/widgets/sorted_contacts/contact_groups_skeleton.dart';
import 'package:anoxia/features/contact/presentation/widgets/sorted_contacts/contact_item_tile.dart';
import 'package:anoxia/framework/domain/chat_contact_vo.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 按字母排序的联系人分组组件
///
/// 使用 AlphabetListView 实现字母索引功能，支持按姓氏首字母分组显示联系人
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
        // 过滤空分组
        final normalizedEntries = groupMap.entries.where((e) {
          final tag = e.key.trim();
          return tag.isNotEmpty && e.value.isNotEmpty;
        }).toList();

        // 构建 AlphabetListViewItemGroup 列表
        final items = normalizedEntries.map((e) {
          final rawChildren = e.value.map((vo) {
            return itemBuilder != null
                ? itemBuilder!(vo)
                : ContactItemTile(contact: vo, onTap: onContactTap);
          }).toList();

          final List<Widget> separatedChildren = [];
          for (var i = 0; i < rawChildren.length; i++) {
            separatedChildren.add(rawChildren[i]);

            if (i < rawChildren.length - 1) {
              separatedChildren.add(
                Divider(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  height: 1,
                  thickness: 1,
                  indent: 56,
                ),
              );
            }
          }

          return AlphabetListViewItemGroup(
            tag: e.key.trim(),
            children: separatedChildren,
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
        return SizedBox.expand(
          child: AlphabetListView(
            items: items,
            options: AlphabetListViewOptions(
              listOptions: ListOptions(
                listHeaderBuilder: (context, tag) =>
                    ContactGroupHeader(tag: tag),
              ),
              overlayOptions: OverlayOptions(
                overlayBuilder: (context, symbol) =>
                    ContactAlphabetOverlay(symbol: symbol),
              ),
              scrollbarOptions: ScrollbarOptions(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.only(right: 4),
                symbolBuilder: (context, symbol, state) =>
                    ContactAlphabetSymbol(
                  symbol: symbol,
                  isActive: state == AlphabetScrollbarItemState.active,
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const ContactGroupsSkeleton(),
      error: (err, stack) =>
          Center(child: Text('${'contact_load_failed_with_error'.tr()}: $err')),
    );
  }
}

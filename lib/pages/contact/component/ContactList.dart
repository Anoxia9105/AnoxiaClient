import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/domain/ChatContactVO.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:anoxia/framework/services/contact_list_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';

class ContactList extends ConsumerWidget {
  const ContactList({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(sortedContactGroupsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        // 触发刷新
        await ref.read(contactListServiceProvider.notifier).refresh();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedAddTeam,
              strokeWidth: 2,
            ),
            title: Text("新的朋友", style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              ref.read(contactSelectionProvider.notifier).selectNewFriends();
            },
          ),
          ListTile(
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedUserGroup03,
              strokeWidth: 2,
            ),
            title: Text("加入的群聊", style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              print("点击了加入的群聊");
            },
          ),
          ListTile(
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedAddTeam,
              strokeWidth: 2,
            ),
            title: Text(
              "联系人",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              print("点击了联系人");
            },
          ),
          Expanded(
            child: groupsAsync.when(
              // 有数据
              data: (groupMap) {
                final items = groupMap.entries
                    .map(
                      (e) => AlphabetListViewItemGroup(
                        tag: e.key,
                        children: e.value.map((vo) => _buildTile(ref, vo)).toList(),
                      ),
                    )
                    .toList();

                return AlphabetListView(
                  items: items,
                  options: AlphabetListViewOptions(
                    listOptions: ListOptions(
                      //标题
                      listHeaderBuilder: (context, tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 4,
                          ),
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.4),
                          child: Text(tag),
                        );
                      },
                    ),
                    //右侧索引
                    scrollbarOptions: ScrollbarOptions(
                      symbols: DefaultScrollbarSymbols.alphabet,
                    ),
                    //索引弹出框
                    overlayOptions: OverlayOptions(
                      overlayBuilder: (context, symbol) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(4),
                            ),
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withValues(alpha: 0.5),
                          ),
                          height: 50.h,
                          width: 20.w,
                          child: FittedBox(
                            child: Center(
                              child: Text(
                                symbol,
                                textScaler: TextScaler.noScaling,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              // 正在加载
              loading: () => const Center(child: CircularProgressIndicator()),
              // 出错了
              error: (err, stack) => Center(child: Text('加载失败: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(WidgetRef ref,ChatContactVO contact) {
    return ListTile(
      key: ValueKey(contact.contactId),
      dense: true,
      title: Text(contact.nickName ?? ''),
      leading: AvatarWidget(
        url: contact.avatar,
        name: contact.nickName,
        status: contact.onlineStatus ?? false
            ? AvatarStatus.online
            : AvatarStatus.offline,
      ),
      onTap: () {
         ref.read(contactSelectionProvider.notifier).selectContact(contact);
      },
    );
  }
}

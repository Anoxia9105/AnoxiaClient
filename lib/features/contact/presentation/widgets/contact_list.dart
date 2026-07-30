import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/VibratingBadge.dart';
import 'package:anoxia/features/contact/presentation/pages/contact_detail_page.dart';
import 'package:anoxia/features/contact/presentation/pages/group_room_list_page.dart';
import 'package:anoxia/features/contact/presentation/pages/new_friends_page.dart';
import 'package:anoxia/features/contact/presentation/widgets/sorted_contacts/sorted_contact_groups_widget.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_requests_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 联系人列表组件
///
/// 显示新朋友、群组列表和联系人分组列表
/// 支持下拉刷新和移动端/桌面端适配
class ContactList extends ConsumerWidget {
  const ContactList({super.key});

  /// 在移动端打开详情页面
  ///
  /// [context] 上下文
  /// [page] 要打开的页面 Widget
  void _openMobileDetail(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingRequests = ref.watch(pendingRequestCountProvider).value ?? 0;
    final (onlineCount, totalCount) = ref.watch(
      contactListServiceProvider.select((s) {
        final contacts = s.value?.values ?? [];

        final total = contacts.length;
        final online = contacts.where((vo) => vo.onlineStatus == true).length;

        return (online, total); // 返回一个解构元组
      }),
    );
    return Scaffold(
      appBar: AppBar(
        centerTitle: DeviceUtil.isRealMobile(),
        titleSpacing: 16,
        title: Text('contact_contacts'.tr()),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(contactListServiceProvider.notifier).refresh();
        },
        child: Column(
          children: [
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedAddTeam),
              title: Text('contact_new_friends'.tr()),
              onTap: () {
                ref.read(contactSelectionProvider.notifier).selectNewFriends();
                if (DeviceUtil.isRealMobile()) {
                  _openMobileDetail(context, const NewFriendsPage());
                }
              },
              trailing: pendingRequests > 0
                  ? VibratingBadge(count: pendingRequests)
                  : const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 18,
                    ),
            ),
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedUserGroup03),
              title: Text('contact_joined_groups'.tr()),
              onTap: () {
                ref.read(contactSelectionProvider.notifier).selectGroups();
                if (DeviceUtil.isRealMobile()) {
                  _openMobileDetail(context, const GroupRoomListPage());
                }
              },
              trailing: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
              ),
            ),

            ListTile(title: Text('sidebar_contact'.tr())),
            Expanded(
              child: SortedContactGroupsWidget(
                onContactTap: () {
                  if (DeviceUtil.isRealMobile()) {
                    _openMobileDetail(context, const ContactDetail());
                  }
                },
              ),
            ),
          ],
        ),
      ),
      persistentFooterAlignment: AlignmentDirectional.centerStart,
      persistentFooterButtons: [
        Text(
          'contact_status_summary'.tr(
            args: [totalCount.toString(), onlineCount.toString()],
          ),
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

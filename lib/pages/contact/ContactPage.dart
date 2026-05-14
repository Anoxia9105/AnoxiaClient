import 'package:anoxia/features/contact/presentation/pages/group_room_list_page.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/contact/presentation/pages/new_friends_page.dart';
import 'package:anoxia/features/contact/presentation/pages/contact_detail_page.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/widgets/Welcome.dart';

class ContactPage extends ConsumerWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (DeviceUtil.isRealMobile()) {
      return const ContactList();
    }

    final selection = ref.watch(
      contactSelectionProvider.select((select) => select.viewType),
    );
    return Row(
      children: [
        SizedBox(width: 100.w, child: const ContactList()),
        Expanded(child: _buildRightContent(selection)),
      ],
    );
  }

  Widget _buildRightContent(ContactViewType viewType) {
    switch (viewType) {
      case ContactViewType.newFriends:
        return const NewFriendsPage();
      case ContactViewType.contactDetail:
        // 将选中的联系人传给详情页
        return const ContactDetail();
      case ContactViewType.groups:
        return const GroupRoomListPage();
      case ContactViewType.none:
        return const Welcome();
    }
  }
}

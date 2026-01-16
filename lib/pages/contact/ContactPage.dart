import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:anoxia/pages/contact/NewfriendsPage.dart';
import 'package:anoxia/pages/contact/component/ContactDetail.dart';
import 'package:anoxia/pages/contact/component/ContactList.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ContactPage extends ConsumerWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(contactSelectionProvider);
       return Row(
      children: [
        SizedBox(width: 80.w, child: ContactList()),
        Expanded(
          child: _buildRightContent(selection),
        ),
      ],
    );
  }

  Widget _buildRightContent(ContactSelectionState selection) {
    switch (selection.viewType) {
      case ContactViewType.newFriends:
        return const NewFriendsPage();
      case ContactViewType.contactDetail:
        // 将选中的联系人传给详情页
        return ContactDetail();
      case ContactViewType.groups:
        return const Center(child: Text("群聊页面"));
      case ContactViewType.none:
      default:
        return const Center(child: Text("请选择一个联系人"));
    }
  }
}
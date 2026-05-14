import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/Welcome.dart';
import 'package:anoxia/features/contact/presentation/pages/contact_detail_page.dart';
import 'package:anoxia/features/contact/presentation/pages/group_room_list_page.dart';
import 'package:anoxia/features/contact/presentation/pages/new_friends_page.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_list.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 联系人页面
///
/// 根据设备类型提供不同的布局：
/// - 移动端：仅显示联系人列表
/// - 桌面端/平板：两栏布局（联系人列表 + 详情内容）
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

  /// 构建右侧详情内容
  ///
  /// 根据 [viewType] 显示不同的内容页面
  ///
  /// [viewType] 视图类型
  /// 返回 对应的详情页面 Widget
  Widget _buildRightContent(ContactViewType viewType) {
    switch (viewType) {
      case ContactViewType.newFriends:
        return const NewFriendsPage();
      case ContactViewType.contactDetail:
        return const ContactDetail();
      case ContactViewType.groups:
        return const GroupRoomListPage();
      case ContactViewType.none:
        return const Welcome();
    }
  }
}

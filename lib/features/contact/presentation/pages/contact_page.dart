import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/features/app/presentation/widgets/welcome.dart';
import 'package:anoxia/features/contact/presentation/pages/contact_detail_page.dart';
import 'package:anoxia/features/contact/presentation/pages/group_room_list_page.dart';
import 'package:anoxia/features/contact/presentation/pages/new_friends_page.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_page/contact_detail_panel.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_list.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 联系人页面
///
/// 根据设备类型提供不同的布局：
/// - 移动端/平板竖屏：仅显示联系人列表，点行 push 详情
/// - 平板横屏/桌面：两栏布局（联系人列表 + 详情内容）
class ContactPage extends ConsumerWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 布局按宽度断点判定：窄屏（含 Web 手机浏览器）仅显示列表；
    // 平板竖屏同样单栏推入，平板横屏走双栏（与聊天页一致）。
    if (DeviceUtil.useSingleColumnPush(context)) {
      return const ContactList();
    }

    final selection = ref.watch(
      contactSelectionProvider.select((select) => select.viewType),
    );
    // 与聊天页面左侧宽度保持一致：平板横屏 280，桌面窄屏 240、宽屏 320
    final isCompactWidth = MediaQuery.of(context).size.width < 1000;
    final leftWidth = DeviceUtil.isTablet(context)
        ? 280.0
        : (isCompactWidth ? 240.0 : 320.0);
    return Row(
      children: [
        SizedBox(
          width: leftWidth,
          // 水平内边距由 ContactList 内部统一提供（12px），
          // 保证列表项与聊天列表的左右节奏一致（未读徽标距右缘 28px）
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: ContactList(),
          ),
        ),
        Expanded(child: _buildRightContent(selection)),
      ],
    );
  }

  /// 根据视图类型构建右侧详情内容
  Widget _buildRightContent(ContactViewType viewType) {
    switch (viewType) {
      case ContactViewType.newFriends:
        return const ContactDetailPanel(child: NewFriendsPage());
      case ContactViewType.contactDetail:
        return const ContactDetailPanel(child: ContactDetail());
      case ContactViewType.groups:
        return const ContactDetailPanel(child: GroupRoomListPage());
      case ContactViewType.none:
        return const ContactDetailPanel(child: Welcome.contacts());
    }
  }
}

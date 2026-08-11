import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../framework/provider/chat/room/room_list_service.dart';
import '../../../framework/provider/contact/contact_requests_controller.dart';
import '../../../framework/provider/layout/layout_controller.dart';
import '../../../framework/provider/setting/update_check_provider.dart';
import '../vibrating_badge.dart';

/// 移动端底部导航栏
///
/// 根据 [LayoutController] 的配置动态生成导航项，
/// 在聊天、联系人、设置等 Tab 上显示未读角标和更新提示。
class MobileBottomBar extends ConsumerWidget {
  const MobileBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(layoutControllerProvider);
    final hasUpdate = ref.watch(hasAppUpdateProvider);
    final pendingRequests = ref.watch(pendingRequestCountProvider).value ?? 0;
    final totalUnread = ref.watch(totalUnreadCountProvider);
    final settingsIndex = layout.items.length - 1;
    const chatIndex = 0;
    const contactsIndex = 1;

    final visibleEntries = layout.items.asMap().entries.where((entry) {
      return entry.value.name != 'sidebar_setting' &&
          entry.value.name != 'sidebar_live';
    }).toList();
    final currentVisibleIndex = visibleEntries.indexWhere(
      (entry) => entry.key == layout.currentIndex,
    );

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentVisibleIndex < 0 ? 0 : currentVisibleIndex,
      selectedItemColor: Theme.of(context).primaryColor,
      onTap: (index) {
        ref
            .read(layoutControllerProvider.notifier)
            .setIndex(visibleEntries[index].key);
      },
      items: visibleEntries.map((entry) {
        final idx = entry.key;
        final item = entry.value;

        Widget iconWidget = HugeIcon(
          icon: item.icon,
          size: 18,
          strokeWidth: 1.5,
        );

        if (idx == chatIndex && totalUnread > 0) {
          iconWidget = Stack(
            clipBehavior: Clip.none,
            children: [
              iconWidget,
              Positioned(
                right: -8,
                top: -6,
                child: VibratingBadge(count: totalUnread),
              ),
            ],
          );
        } else if (idx == contactsIndex && pendingRequests > 0) {
          iconWidget = Stack(
            clipBehavior: Clip.none,
            children: [
              iconWidget,
              Positioned(
                right: -8,
                top: -6,
                child: VibratingBadge(count: pendingRequests),
              ),
            ],
          );
        } else if (idx == settingsIndex && hasUpdate) {
          iconWidget = Stack(
            clipBehavior: Clip.none,
            children: [
              iconWidget,
              const Positioned(
                right: -8,
                top: -6,
                child: VibratingBadge(isDot: true),
              ),
            ],
          );
        }

        return BottomNavigationBarItem(icon: iconWidget, label: item.name.tr());
      }).toList(),
    );
  }
}

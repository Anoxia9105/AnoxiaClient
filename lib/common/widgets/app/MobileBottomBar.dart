import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../framework/provider/contact/contact_requests_controller.dart';
import '../../../framework/provider/layout/layout_controller.dart';
import '../../../framework/provider/chat/room/room_list_service.dart';
import '../../../framework/provider/setting/update_check_provider.dart';
import '../VibratingBadge.dart';

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

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: layout.currentIndex,
      selectedItemColor: Theme.of(context).primaryColor,
      onTap: (index) {
        ref.read(layoutControllerProvider.notifier).setIndex(index);
      },
      items: layout.items.asMap().entries.map((entry) {
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
              Positioned(
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

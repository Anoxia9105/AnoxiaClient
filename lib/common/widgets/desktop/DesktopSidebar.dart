import 'package:anoxia/common/widgets/VibratingBadge.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/contact/contact_requests_controller.dart';
import 'package:anoxia/framework/provider/setting/update_check_provider.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';

import '../../../framework/provider/layout/layout_controller.dart';
import '../../../framework/provider/ws/ws_controller.dart';
import '../../../framework/provider/ws/ws_state.dart';
import '../AvatarWidget.dart';
import '../BubbleDialog.dart';
import '../Toast.dart';

class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    context.locale; // 监听 locale 变化以触发重建
    final layout = ref.watch(layoutControllerProvider);
    final user = ref.watch(authControllerProvider);
    final status = ref.watch(wsControllerProvider.select((s) => s.status));
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          // 用户信息位置
          Builder(
            builder: (context) {
              return InkWell(
                child: AvatarWidget(
                  url: user.value?.avatar,
                  name: user.value?.nickName,
                  size: 35,
                  status: status == WsStatus.connected
                      ? AvatarStatus.online
                      : AvatarStatus.offline,
                ),
                onTap: () => _showUserDetail(context, ref, user.value, status),
              );
            },
          ),
          const SizedBox(height: 8),
          // 导航栏
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: List.generate(layout.items.length - 1, (index) {
                final item = layout.items[index];
                return SidebarButton(
                  padding: EdgeInsets.all(10),
                  index: index,
                  name: item.name.tr(),
                  icon: item.icon,
                );
              }),
            ),
          ),

          SidebarButton(
            padding: EdgeInsets.all(10),
            index: layout.items.length - 1,
            name: layout.items[layout.items.length - 1].name.tr(),
            icon: layout.items[layout.items.length - 1].icon,
          ),
        ],
      ),
    );
  }

  void _showUserDetail(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    WsStatus status,
  ) {
    Function? close;
    close = Toast.showWidget(
      context,
      direction: PreferDirection.rightTop,
      child: Material(
        color: Colors.transparent,
        child: BubbleWidget(
          arrowDirection: AxisDirection.left,
          arrowOffset: 25,
          backgroundColor: Theme.of(context).colorScheme.surface,
          border: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
          contentBuilder: (context) => Container(
            constraints: BoxConstraints(maxWidth: 220, maxHeight: 600),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    AvatarWidget(
                      url: user?.avatar,
                      name: user?.nickName,
                      size: 50,
                      status: status == WsStatus.connected
                          ? AvatarStatus.online
                          : AvatarStatus.offline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.nickName ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            user?.email ?? 'No Email',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                // SizedBox(
                //   width: double.infinity,
                //   child: TextButton.icon(
                //     onPressed: () {
                //       ref.read(authControllerProvider.notifier).logout();
                //       close?.call();
                //     },
                //     label: Text('sidebar_personal_details'.tr()),
                //     icon: HugeIcon(icon: HugeIcons.strokeRoundedUser),
                //   ),
                // ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).logout();
                      close?.call();
                    },
                    label: Text('sidebar_logout'.tr(), style: TextStyle(color: Colors.red)),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedLogout01,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//侧边栏按钮
class SidebarButton extends ConsumerWidget {
  final int index;
  final String name;
  final List<List<dynamic>> icon;
  final EdgeInsetsGeometry padding;

  const SidebarButton({
    super.key,
    required this.index,
    required this.name,
    required this.icon,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(layoutControllerProvider);
    final bool isActive = layout.currentIndex == index;

    final unreadCount = ref.watch(totalUnreadCountProvider);
    final hasUpdate = ref.watch(hasAppUpdateProvider);
    final pendingRequests = ref.watch(pendingRequestCountProvider).value ?? 0;
    // settings 是最后一个 item（index = items.length - 1）
    final settingsIndex = layout.items.length - 1;
    // contacts 是 index 1
    const contactsIndex = 1;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(layoutControllerProvider.notifier).setIndex(index);
          },
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    HugeIcon(
                      icon: icon,
                      color: isActive ? Theme.of(context).primaryColor : null,
                      size: 18,
                      strokeWidth: 1.5,
                    ),

                    if (index == 0 && unreadCount > 0)
                      Positioned(
                        right: -15,
                        top: -8,
                        child: VibratingBadge(count: unreadCount),
                      ),

                    if (index == contactsIndex && pendingRequests > 0)
                      Positioned(
                        right: -8,
                        top: -6,
                        child: VibratingBadge(count: pendingRequests),
                      ),

                    if (index == settingsIndex && hasUpdate)
                      Positioned(
                        right: -8,
                        top: -6,
                        child: VibratingBadge(isDot: true),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    color: isActive ? Theme.of(context).primaryColor : null,
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

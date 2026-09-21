import 'package:anoxia/common/widgets/vibrating_badge.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/dialogs/logout_confirm_dialog.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/provider/contact/contact_requests_controller.dart';
import 'package:anoxia/framework/provider/layout/desktop_layout_controller.dart';
import 'package:anoxia/framework/provider/setting/update_check_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';

import '../../../framework/provider/layout/layout_controller.dart';
import '../../../framework/provider/ws/ws_controller.dart';
import '../../../framework/provider/ws/ws_state.dart';
import '../avatar_widget.dart';

/// 桌面端侧边栏组件
///
/// 提供导航功能，包含：
/// - 用户头像（显示在线状态）
/// - 导航按钮（聊天、联系人、设置等）
/// - 未读消息、好友请求、更新通知徽章
class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({super.key, required this.layoutStyle});

  final DesktopLayoutStyle layoutStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    context.locale; // 监听 locale 变化以触发重建
    final layout = ref.watch(layoutControllerProvider);
    final user = ref.watch(authControllerProvider);
    final status = ref.watch(wsControllerProvider.select((s) => s.status));
    final colorScheme = Theme.of(context).colorScheme;
    final isCard = layoutStyle == DesktopLayoutStyle.card;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return SizedBox(
      width: isCard ? 82 : 70,
      child: Padding(
        padding: isCard
            ? EdgeInsets.fromLTRB(8, DeviceUtil.isWeb ? 12 : 8, 4, 16)
            : EdgeInsets.only(top: DeviceUtil.isWeb ? 12 : 0),
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isCard
                ? colorScheme.surface.withValues(alpha: 0.84)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(isCard ? RadiusToken.xl : 0),
            border: isCard
                ? Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.34),
                  )
                : null,
            boxShadow: isCard
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.22
                            : 0.08,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              if (isCard) const SizedBox(height: 10),
              InkWell(
                mouseCursor: SystemMouseCursors.click,
                child: AvatarWidget(
                  url: user.value?.avatar,
                  name: user.value?.nickName,
                  size: 35,
                  status: status == WsStatus.connected
                      ? AvatarStatus.online
                      : AvatarStatus.offline,
                ),
                onTap: () =>
                    ref.read(layoutControllerProvider.notifier).setToUser(),
              ),
              const SizedBox(height: 8),
              // 导航栏
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: List.generate(layout.items.length, (index) {
                    final item = layout.items[index];
                    return SidebarButton(
                      padding: const EdgeInsets.all(10),
                      layoutStyle: layoutStyle,
                      index: index,
                      name: item.name == 'sidebar_favorites'
                          ? 'sidebar_favorites_short'.tr()
                          : item.name.tr(),
                      icon: item.icon,
                    );
                  }),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: IconButton(
                    tooltip: 'sidebar_logout'.tr(),
                    onPressed: () async {
                      // 弹出确认对话框
                      final shouldLogout = await showLogoutConfirmDialog(
                        context,
                      );
                      // 如果用户点击了“确定”且对话框未关闭，执行登出
                      if (shouldLogout) {
                        ref.read(authControllerProvider.notifier).logout();
                      }
                    },
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedLogout01,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// 侧边栏导航按钮
class SidebarButton extends ConsumerWidget {
  final int index;
  final String name;
  final List<List<dynamic>> icon;
  final EdgeInsetsGeometry padding;
  final DesktopLayoutStyle layoutStyle;

  const SidebarButton({
    super.key,
    required this.index,
    required this.name,
    required this.icon,
    required this.layoutStyle,
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
    final isCard = layoutStyle == DesktopLayoutStyle.card;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: isCard
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
          : EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: isCard && isActive
              ? colorScheme.primaryContainer.withValues(alpha: 0.46)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(isCard ? RadiusToken.lg : 0),
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(isCard ? RadiusToken.lg : 0),
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

                      /// 更新通知仅显示红点
                      if (index == settingsIndex && hasUpdate)
                        const Positioned(
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
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

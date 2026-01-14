import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/framework/provider/auth/auth_controller.dart';

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
    final layout = ref.watch(layoutControllerProvider);
    final user = ref.watch(authControllerProvider);
    final locale = context.locale;
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
                onTap: () {
                  Function? close;
                  close = Toast.showWidget(
                    context,
                    direction: PreferDirection.rightTop,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 90.w),
                      child: BubbleWidget(
                        arrowDirection: AxisDirection.left,
                        arrowOffset: 20,
                        arrowLength: 6,
                        arrowRadius: 3,
                        arrowWidth: 17,
                        border: BorderSide(
                          width: 1,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainer,
                        contentBuilder: (context) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user.value?.nickName ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                user.value?.email ?? 'No Email',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              FilledButton(
                                onPressed: () {
                                  ref
                                      .read(authControllerProvider.notifier)
                                      .logout();
                                  close?.call();
                                },
                                child: Text("退出登录"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
}

//侧边栏按钮
class SidebarButton extends ConsumerWidget {
  final int index;
  final String name;
  final IconData icon;
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
                HugeIcon(
                  icon: icon,
                  color: isActive ? Theme.of(context).primaryColor : null,
                  size: 18,
                ),
                Text(
                  name,
                  style: TextStyle(
                    color: isActive ? Theme.of(context).primaryColor : null,
                    fontSize: 12,
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

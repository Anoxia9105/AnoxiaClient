import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../framework/provider/layout/layout_controller.dart';
import '../../framework/services/auth_service.dart';
import '../../shared/widgets/AvatarWidget.dart';
import '../../shared/widgets/BubbleDialog.dart';
import '../../shared/widgets/Toast.dart';

class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(layoutControllerProvider);
    final user = ref.watch(userInfoProvider);

    return SizedBox(
      width: 60,
      child: Column(
        children: [
          const SizedBox(height: 16),
          // 用户信息位置
          Builder(
            builder: (context) {
              return user.when(
                data: (u) => InkWell(
                  child: AvatarWidget(
                    url: u.avatar,
                    name: u.nickName,
                    size: 35,
                  ),
                  onTap: () {
                    Function? close;
                    close = Toast.showWidget(
                      context,
                      direction: PreferDirection.rightTop,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 300),
                        child: Material(
                          type: MaterialType.transparency,
                          child: BubbleWidget(
                            arrowDirection: AxisDirection.left,
                            arrowOffset: 20,
                            arrowLength: 6,
                            arrowRadius: 3,
                            arrowWidth: 17,
                            borderRadius: BorderRadius.circular(4),
                            border: BorderSide(
                              width: 1,
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            contentBuilder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(6, (index) {
                                if (index.isEven) {
                                  return Text("data");
                                } else {
                                  return Divider();
                                }
                              }),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                loading: () => CircularProgressIndicator(),
                error: (e, st) => Text("加载失败"),
              );
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: List.generate(layout.options.length, (index) {
                final page = layout.options[index];
                return SidebarButton(
                  padding: EdgeInsets.all(10),
                  index: index,
                  name: page.name.tr(),
                  icon: page.icon,
                );
              }),
            ),
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
    this.padding=const EdgeInsets.all(8.0)
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(layoutControllerProvider);
    final bool isActive = layout.currentIndex == index;
    return Material(
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
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

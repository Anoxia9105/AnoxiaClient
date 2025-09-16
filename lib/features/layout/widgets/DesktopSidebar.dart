import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/features/layout/controller/LayoutController.dart';
import 'package:notepadclient/shared/widgets/Application.dart';

import '../../../core/di/injector.dart';

/// 桌面环境导航栏
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  17:41

class DesktopSidebar extends StatefulWidget {
  const DesktopSidebar({super.key});

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar> {
  final LayoutController layoutController = getIt<LayoutController>();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Teams 图标位置
          IconButton(
            onPressed: () {},
            icon: Application.getAppLogo(width: 24, height: 24),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SidebarButton(
                  index: 0,
                  name: "聊天",
                  icon: HugeIcons.strokeRoundedComment01,
                ),
                SidebarButton(
                  index: 1,
                  name: "联系",
                  icon: HugeIcons.strokeRoundedContact01,
                ),
                SidebarButton(
                  index: 2,
                  name: "文档",
                  icon: HugeIcons.strokeRoundedNote01,
                ),
                SidebarButton(
                  index: 3,
                  name: "发现",
                  icon: HugeIcons.strokeRoundedPathfinderCrop,
                ),
                SidebarButton(
                  index: 4,
                  name: "我的",
                  icon: HugeIcons.strokeRoundedUser,
                ),
              ],
            ),
          ),
          SidebarButton(
            index: 5,
            name: "设置",
            icon: HugeIcons.strokeRoundedSettings01,
          ),
        ],
      ),
    );
  }
}

class SidebarButton extends StatelessWidget {
  final int index;
  final String name;
  final IconData icon;

  SidebarButton({
    super.key,
    required this.index,
    required this.name,
    required this.icon,
  });

  final LayoutController layoutController = getIt<LayoutController>();

  @override
  Widget build(BuildContext context) {
    LayoutController layoutController = getIt<LayoutController>();
    final bool isActive = layoutController.currentIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          layoutController.changeIndex(index);
        },
        child: SizedBox(
          width: 70,
          height: 70,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

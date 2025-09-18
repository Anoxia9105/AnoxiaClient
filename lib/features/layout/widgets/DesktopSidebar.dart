import 'package:easy_localization/easy_localization.dart';
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
            icon: Application.getAppLogo(width: 30, height: 30),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children:
                  layoutController.options.asMap().entries.map((entry) {
                    int idx = entry.key;
                    LayoutOptions option = entry.value;
                    return SidebarButton(
                      index: idx,
                      name: option.localizedName,
                      icon: option.icon,
                    );
                  }).toList(),
            ),
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

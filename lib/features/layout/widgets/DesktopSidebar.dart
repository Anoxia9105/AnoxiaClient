import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/features/layout/controller/LayoutController.dart';
import 'package:notepadclient/shared/widgets/Application.dart';
import 'package:url_launcher/url_launcher.dart';

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
          // logo 图标位置
          InkWell(
            child: Center(child: Application.getAppLogo(width: 30,height: 30)),
            onTap: ()=>openLink(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: List.generate(
                layoutController.layoutPageList.length,
                (index) {
                  final page = layoutController.layoutPageList[index];
                  return SidebarButton(
                    index: index,
                    name: page.localizedName,
                    icon: page.icon,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openLink() async {
    final Uri url = Uri.parse("https://flutter.dev");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw "无法打开 $url";
    }
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

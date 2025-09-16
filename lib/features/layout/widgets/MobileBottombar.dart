import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/features/layout/controller/LayoutController.dart';

import '../../../core/di/injector.dart';

/// 手机端底部导航栏
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  18:36
class MobileBottomBar extends StatefulWidget {
  const MobileBottomBar({super.key});

  @override
  State<MobileBottomBar> createState() => _MobileBottomBarState();
}

class _MobileBottomBarState extends State<MobileBottomBar> {
  final LayoutController layoutController = getIt<LayoutController>();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: layoutController.currentIndex,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        layoutController.changeIndex(index);
      },
      items: const [
        BottomNavigationBarItem(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedComment01, size: 20),
          label: "聊天",
        ),
        BottomNavigationBarItem(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedContact01, size: 20),
          label: "联系",
        ),
        BottomNavigationBarItem(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedNote01, size: 20),
          label: "文档",
        ),
        BottomNavigationBarItem(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedPathfinderCrop, size: 20),
          label: "发现",
        ),
        BottomNavigationBarItem(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 20),
          label: "我的",
        ),
        BottomNavigationBarItem(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedSettings01, size: 20),
          label: "设置",
        ),
      ],
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
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
      onTap: (index) {
        layoutController.changeIndex(index);
      },
      items:
          layoutController.layoutPages.asMap().entries.where((entry) => entry.value.show == false).map((entry) {
            LayoutOptions option = entry.value;
            return BottomNavigationBarItem(
              icon: HugeIcon(icon: option.icon, size: 18),
              label: option.localizedName,
            );
          }).toList(),
    );
  }
}

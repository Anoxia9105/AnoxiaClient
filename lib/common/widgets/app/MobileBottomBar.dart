import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../framework/provider/layout/layout_controller.dart';

class MobileBottomBar extends ConsumerWidget {
  const MobileBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(layoutControllerProvider);
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: layout.currentIndex,
      selectedItemColor: Theme.of(context).primaryColor,
      onTap: (index) {
        ref.read(layoutControllerProvider.notifier).setIndex(index);
      },
      items: layout.items.map((item) {
        return BottomNavigationBarItem(
          icon: HugeIcon(icon: item.icon, size: 18, strokeWidth: 1.5),
          label: item.name.tr(),
        );
      }).toList(),
    );
  }
}

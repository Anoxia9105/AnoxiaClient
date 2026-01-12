import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';


part 'layout_controller.g.dart';

@riverpod
class LayoutController extends _$LayoutController {
// 静态配置：作为控制器的私有常量
  static const _menuItems = [
    SidebarItem(name: "sidebar_chat", icon: HugeIcons.strokeRoundedComment01),
    SidebarItem(name: "sidebar_contact", icon: HugeIcons.strokeRoundedContact01),
    SidebarItem(name: "sidebar_documentation", icon: HugeIcons.strokeRoundedNote01),
    SidebarItem(name: "sidebar_discover", icon: HugeIcons.strokeRoundedPathfinderCrop),
    SidebarItem(name: "sidebar_my", icon: HugeIcons.strokeRoundedUser),
  ];

  @override
  LayoutState build() {
    return LayoutState(
      currentIndex: 0,
      extendedValue: false,
      items: _menuItems,
    );
  }

  void setIndex(int index) {
    if (state.currentIndex != index) {
      state = state.copyWith(currentIndex: index);
    }
  }

  void toggleExtended() {
    state = state.copyWith(extendedValue: !state.extendedValue);
  }
}

class LayoutState {
  final int currentIndex;
  final bool extendedValue;
  final List<SidebarItem> items; // 只存名字索引

  LayoutState({
    required this.currentIndex,
    required this.extendedValue,
    required this.items,
  });

  LayoutState copyWith({int? currentIndex, bool? extendedValue}) {
    return LayoutState(
      currentIndex: currentIndex ?? this.currentIndex,
      extendedValue: extendedValue ?? this.extendedValue,
      items: items,
    );
  }
}


class SidebarItem {
  final String name;
  final IconData icon;

  const SidebarItem({required this.name, required this.icon});
}
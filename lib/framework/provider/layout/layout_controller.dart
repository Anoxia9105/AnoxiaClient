import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hugeicons/hugeicons.dart';

part 'layout_controller.g.dart';

/// 布局状态管理器
///
/// 控制桌面端的侧边栏状态、当前选中页面索引等。
@riverpod
class LayoutController extends _$LayoutController {
  static const _menuItems = [
    SidebarItem(name: 'sidebar_chat', icon: HugeIcons.strokeRoundedComment01),
    SidebarItem(
      name: 'sidebar_contact',
      icon: HugeIcons.strokeRoundedContact01,
    ),
    SidebarItem(
      name: 'sidebar_favorites',
      icon: HugeIcons.strokeRoundedFavourite,
    ),
    SidebarItem(
      name: 'sidebar_note',
      icon: HugeIcons.strokeRoundedNote01,
    ),
    SidebarItem(
      name: 'sidebar_schedule',
      icon: HugeIcons.strokeRoundedCalendar03,
    ),
    SidebarItem(name: 'sidebar_my', icon: HugeIcons.strokeRoundedUser),
    SidebarItem(
      name: 'sidebar_setting',
      icon: HugeIcons.strokeRoundedSettings01,
    ),
  ];

  @override
  LayoutState build() {
    return LayoutState(
      currentIndex: 0,
      items: _menuItems,
    );
  }

  /// 设置当前选中的页面索引
  void setIndex(int index) {
    if (index < 0 || index >= state.items.length) {
      return;
    }
    if (state.currentIndex != index) {
      state = state.copyWith(currentIndex: index);
    }
  }

  /// 设置当前选中的页面为用户页面
  void setToUser() {
    final userIndex = state.items.indexWhere(
      (item) => item.name == 'sidebar_my',
    );
    if (userIndex != -1) {
      setIndex(userIndex);
    }
  }

  /// 设置当前选中的页面为记事本页面
  void setToNotes() {
    final noteIndex = state.items.indexWhere(
      (item) => item.name == 'sidebar_note',
    );
    if (noteIndex != -1) {
      setIndex(noteIndex);
    }
  }
}

/// 布局状态数据类
class LayoutState {
  /// 当前选中的页面索引
  final int currentIndex;

  /// 菜单项列表
  final List<SidebarItem> items;

  LayoutState({
    required this.currentIndex,
    required this.items,
  });

  LayoutState copyWith({int? currentIndex}) {
    return LayoutState(
      currentIndex: currentIndex ?? this.currentIndex,
      items: items,
    );
  }
}

/// 侧边栏菜单项
class SidebarItem {
  /// 国际化 key
  final String name;

  /// 图标数据
  final List<List<dynamic>> icon;

  const SidebarItem({required this.name, required this.icon});
}

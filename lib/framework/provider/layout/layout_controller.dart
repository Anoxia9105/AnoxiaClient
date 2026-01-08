import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../pages/ThemeTestPage.dart';
import '../../../pages/chat/ChatPage.dart';

part 'layout_controller.g.dart';

@riverpod
class LayoutController extends _$LayoutController {
  late final List<LayoutOptions> _layoutPageList = [
    LayoutOptions(
      name: "sidebar_chat",
      icon: HugeIcons.strokeRoundedComment01,
      page: const ChatPage(),
    ),
    LayoutOptions(
      name: "sidebar_contact",
      icon: HugeIcons.strokeRoundedContact01,
      page: const Text("Contact"),
    ),
    LayoutOptions(
      name: "sidebar_documentation",
      icon: HugeIcons.strokeRoundedNote01,
      page: const Text("sidebar_documentation"),
    ),
    LayoutOptions(
      name: "sidebar_discover",
      icon: HugeIcons.strokeRoundedPathfinderCrop,
      page: const Text("sidebar_discover"),
    ),
    LayoutOptions(
      name: "sidebar_my",
      icon: HugeIcons.strokeRoundedUser,
      page: const ThemeTestPage(),
    ),
  ];

  @override
  LayoutState build() {
    return LayoutState(
      currentIndex: 0,
      extendedValue: false,
      indexedStackPages: _layoutPageList.map((e) => e.page).toList(),
      options: _layoutPageList,
    );
  }

  void setIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void setExtended(bool value) {
    state = state.copyWith(extendedValue: value);
  }

  void startListen() {
    // 你原来的逻辑写这里
  }
}

class LayoutState {
  //当前索引
  final int currentIndex;

  //win 最大化/正常
  final bool extendedValue;

  // 页面列表
  final List<Widget> indexedStackPages;

  final List<LayoutOptions> options;

  LayoutState({
    required this.currentIndex,
    required this.extendedValue,
    required this.indexedStackPages,
    required this.options,
  });

  LayoutState copyWith({
    int? currentIndex,
    bool? extendedValue,
    List<Widget>? indexedStackPages,
    List<LayoutOptions>? options,
  }) {
    return LayoutState(
      currentIndex: currentIndex ?? this.currentIndex,
      extendedValue: extendedValue ?? this.extendedValue,
      indexedStackPages: indexedStackPages ?? this.indexedStackPages,
      options: options ?? this.options,
    );
  }
}

//布局页面项
class LayoutOptions {
  final String name;
  final IconData icon;
  final Widget page;

  LayoutOptions({required this.name, required this.icon, required this.page});
}

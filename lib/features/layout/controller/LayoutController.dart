import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/features/chat/pages/ChatPage.dart';
import 'package:notepadclient/features/setting/pages/SettingPage.dart';

/// 布局控制器
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  18:16
class LayoutController extends ChangeNotifier {

  bool isLogin=false;

  set login(bool value) {
    isLogin = value;
    notifyListeners();
  }

  ///MAX | MIN
  ///最大最小化 图标切换
  bool _extended = false;
  bool get extended => _extended;
  set extendedValue(bool value) {
    _extended = value;
    notifyListeners();
  }

  int currentIndex = 0;

  ///用于控制页面的切换
  PageController pageController = PageController();

  void changeIndex(int index) {
    currentIndex = index;
    pageController.jumpToPage(index);
    notifyListeners();
  }

  final List<LayoutOptions> options = [
    LayoutOptions(
      name: "sidebar_chat",
      icon: HugeIcons.strokeRoundedComment01,
      page: const ChatPage(),
    ),
    LayoutOptions(
      name: "sidebar_contact",
      icon: HugeIcons.strokeRoundedContact01,
      page: const Text("sidebar_contact"),
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
      page: const Text("sidebar_my"),
    ),
    LayoutOptions(
      name: "sidebar_settings",
      icon: HugeIcons.strokeRoundedSettings01,
      page: const SettingPage(),
    ),
  ];
}

class LayoutOptions {
  final String name;
  final IconData icon;
  final Widget page;

  String get localizedName => name.tr();
  LayoutOptions({required this.name, required this.icon, required this.page});
}

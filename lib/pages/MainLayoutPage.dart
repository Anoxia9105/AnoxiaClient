import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notepadclient/pages/desktop/DesktopAppBar.dart';
import 'package:notepadclient/shared/widgets/Application.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../common/utils/DeviceUtil.dart';
import '../framework/provider/auth/auth_state_provider.dart';
import '../framework/provider/layout/layout_controller.dart';
import '../framework/theme/AppColors.dart';
import '../gen/assets.gen.dart';
import 'desktop/DesktopSidebar.dart';

class MainLayoutPage extends ConsumerStatefulWidget {
  const MainLayoutPage({super.key});

  @override
  ConsumerState<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends ConsumerState<MainLayoutPage>
    with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();

    if (DeviceUtil.isRealDesktop()) {
      _initTray();

      ref.read(layoutControllerProvider.notifier).startListen();

      windowManager.addListener(this);
      trayManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (DeviceUtil.isRealDesktop()) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    ref.read(layoutControllerProvider.notifier).setExtended(true);
  }

  @override
  void onWindowUnmaximize() {
    ref.read(layoutControllerProvider.notifier).setExtended(false);
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'hide_window') {
      windowManager.hide();
    } else if (menuItem.key == 'exit_app') {
      windowManager.close();
    }
  }

  Future<void> _initTray() async {
    await trayManager.setIcon(Assets.images.appIconIco);
    await trayManager.setToolTip("anoxia");

    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'show_window', label: '显示窗口'),
          MenuItem(key: 'hide_window', label: '隐藏窗口'),
          MenuItem.separator(),
          MenuItem(key: 'exit_app', label: '退出'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("🛠️ MainLayoutPage 开始构建: ${DateTime.now().millisecond}ms");
    //获取主题渐变色
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;
    // 如果没有渐变，则给一个主题相关的底色
    final baseColor = Theme.of(context).scaffoldBackgroundColor;

    final layout = ref.watch(layoutControllerProvider);

    //最小尺寸检测
    final size = MediaQuery.of(context).size;
    if (size.width < 320 || size.height <= 320) {
      return Scaffold(
        body: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Application.getAppLogo(
              child: Text(
                "layout_min_size_error".tr(),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    //外层Scaffold
    return Scaffold(
      //默认背景色是白色，防止闪屏时看到黑色背景
      backgroundColor: baseColor,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(gradient: gradient),
        child: Row(
          children: [
            //如果是桌面或平板，显示侧边栏
            if (DeviceUtil.isDesktop(context) || DeviceUtil.isTablet(context))
              const DesktopSidebar(),

            //主内容区
            Expanded(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: getAppbar(
                  extended: layout.extendedValue,
                  bakColor: Colors.transparent,
                ),
                body: IndexedStack(
                  index: layout.currentIndex,
                  children: layout.indexedStackPages,
                ),
              ),
            ),
          ],
        ),
      ),

      //如果是移动设备，显示底部导航栏
      bottomNavigationBar:
          // DeviceUtil.isMobile(context) ? const MobileBottomBar() : null,
          DeviceUtil.isMobile(context) ? const Text("Android") : null,
    );
  }

  //获取应用栏
  PreferredSizeWidget getAppbar({
    required bool extended,
    Color? iconColor,
    Color? bakColor,
  }) {
    if (DeviceUtil.isRealDesktop()) {
      return DesktopAppBar(
        extended: extended,
        iconColor: iconColor,
        backgroundColor: bakColor,
      );
    }

    return AppBar(title: Text("Mobile Header"));
  }
}

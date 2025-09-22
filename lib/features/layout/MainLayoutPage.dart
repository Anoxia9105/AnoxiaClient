import 'package:flutter/material.dart';
import 'package:notepadclient/core/utils/DeviceUtil.dart';
import 'package:notepadclient/features/auth/pages/LoginPage.dart';
import 'package:notepadclient/features/layout/controller/LayoutController.dart';
import 'package:notepadclient/features/layout/widgets/DesktopSidebar.dart';
import 'package:notepadclient/features/layout/widgets/LayoutHeader.dart';
import 'package:notepadclient/features/layout/widgets/MobileBottombar.dart';
import 'package:notepadclient/shared/theme/AppColors.dart';
import 'package:notepadclient/shared/widgets/Application.dart';
import 'package:notepadclient/shared/widgets/FocusOverlayManager.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/di/injector.dart';



/// APP 主布局文件
///
/// 用途：布局主入口
/// 作者：USER
/// 创建时间：2025-09-17
class MainLayoutPage extends StatefulWidget {
  const MainLayoutPage({super.key});

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage>
    with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    if (DeviceUtil.isDesktop) {
      _initTray();
      Provider.of<LayoutController>(context, listen: false).startListen(context);
      windowManager.addListener(this);
      trayManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (DeviceUtil.isDesktop) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  //窗口最大化
  @override
  void onWindowMaximize() {
    super.onWindowMaximize();
    Provider.of<LayoutController>(context, listen: false).extendedValue = true;
  }

  //窗口恢复
  @override
  void onWindowUnmaximize() {
    super.onWindowUnmaximize();
    Provider.of<LayoutController>(context, listen: false).extendedValue = false;
  }

  @override
  void onTrayIconMouseDown() {
    // 当托盘图标被点击时，显示窗口
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
    // 当托盘图标右键被点击时，弹出菜单
  }

  @override
  void onTrayIconRightMouseUp() {
    // do something
    // 当托盘图标右键被释放时，可以执行其他操作
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
    await trayManager.setIcon('assets/images/app_icon.ico');
    await trayManager.setToolTip("anoxia");

    List<MenuItem> items = [
      MenuItem(key: 'show_window', label: '显示窗口'),
      MenuItem(key: 'hide_window', label: '隐藏窗口'),
      MenuItem.separator(),
      MenuItem(key: 'exit_app', label: '退出'),
    ];

    await trayManager.setContextMenu(Menu(items: items));
  }

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;

    return Consumer<LayoutController>(
      builder: (BuildContext context, LayoutController layout, Widget? child) {
        //如果未登录，则跳转到登录页面
        if (!layout.isLogin) {
          return LoginPage();
        }
        return Container(
          decoration: BoxDecoration(gradient: gradient),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: () {
             return Row(
                children: [
                  // 侧边栏
                  if (!DeviceUtil.isMobile && !DeviceUtil.isWeb)
                    DesktopSidebar(),
                  // 主内容区域
                  Expanded(
                    child: Scaffold(
                      appBar: LayoutHeader().getAppbar(),
                      body: PageView(
                        controller: layout.pageController,
                        // 禁止滑动
                        physics: const NeverScrollableScrollPhysics(),
                        children: layout.options.map((e) => e.page).toList(),
                      ),
                    ),
                  ),
                ],
              );
            }(),
            bottomNavigationBar: DeviceUtil.isMobile || DeviceUtil.isWeb
                ? MobileBottomBar()
                : null,
          ),
        );
      },
    );
  }
}

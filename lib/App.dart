import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'common/utils/DeviceUtil.dart';
import 'framework/provider/layout/layout_controller.dart';
import 'framework/provider/router/router.dart';
import 'gen/assets.gen.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    if (DeviceUtil.isRealDesktop()) {
      _initTray();
      windowManager.setPreventClose(true);
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
    ref.read(layoutControllerProvider.notifier).toggleExtended();
  }

  @override
  void onWindowUnmaximize() {
    ref.read(layoutControllerProvider.notifier).toggleExtended();
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
      windowManager.setPreventClose(false);
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
    final locale = context.locale;
    return MaterialApp.router(
      title: '记事本客户端',
      routerConfig: ref.watch(routerProvider),
      theme: ref.watch(appThemeProvider),
      builder: BotToastInit(),
      debugShowCheckedModeBanner: false,
      locale: locale,
    );
  }
}

import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'common/utils/DeviceUtil.dart';
import 'framework/provider/layout/layout_controller.dart';
import 'framework/provider/chat/room/room_list_service.dart';
import 'framework/provider/router/router.dart';
import 'framework/provider/chat/message/system_event_service.dart';
import 'gen/assets.gen.dart';
import 'common/utils/NotificationHelper.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WindowListener, TrayListener {
  ProviderSubscription<int>? _unreadBadgeSubscription;

  @override
  void initState() {
    super.initState();
    // 全局启动系统事件监听服务（禁言/封禁/解散等事件分发入口）
    ref.read(systemEventServiceProvider);

    if (DeviceUtil.isRealDesktop()) {
      _initTray();
      windowManager.setPreventClose(true);
      windowManager.addListener(this);
      trayManager.addListener(this);
    }

    if (DeviceUtil.isRealMobile()) {
      _unreadBadgeSubscription = ref.listenManual<int>(
        totalUnreadCountProvider,
        (previous, next) {
          NotificationHelper().updateAppIconBadge(next);
        },
        fireImmediately: true,
      );
    }
  }

  @override
  void dispose() {
    _unreadBadgeSubscription?.close();

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
          MenuItem(key: 'show_window', label: 'tray_show_window'.tr()),
          MenuItem(key: 'hide_window', label: 'tray_hide_window'.tr()),
          MenuItem.separator(),
          MenuItem(key: 'exit_app', label: 'tray_exit'.tr()),
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
      localizationsDelegates: [
        ...context.localizationDelegates,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: context.supportedLocales,
    );
  }
}

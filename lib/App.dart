import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notepadclient/framework/protocol/message/HighMessage.dart';
import 'package:notepadclient/framework/provider/theme/theme_controller.dart';
import 'package:notepadclient/framework/services/high_message_service.dart';
import 'package:notepadclient/pages/SplashPage.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'common/utils/DeviceUtil.dart';
import 'framework/logs/talker.dart';
import 'framework/provider/auth/auth_controller.dart';
import 'framework/provider/core/app_initializer.dart';
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
    // 💡 监听高优消息 Service
    ref.listen(highMessageServiceProvider, (prev, next) {
      // 1. 遍历 next 中的所有房间状态
      for (var roomId in next.keys) {
        final roomStatus = next[roomId]!;

        // --- 场景 A: 通话邀请 ---
        if (roomStatus.containsKey(HighMessageType.CALL_INVITE)) {
          final inviteMsg = roomStatus[HighMessageType.CALL_INVITE]!;
          // 检查 prev 中是否已经存在这个邀请，防止由于其他类型消息更新导致的重复触发
          final alreadyInvited =
              prev?[roomId]?.containsKey(HighMessageType.CALL_INVITE) ?? false;

          if (!alreadyInvited) {
            log.info("检测到新通话邀请，准备弹出接听界面: ${inviteMsg.senderId}");
            _showIncomingCallDialog(inviteMsg);
          }
        }

        // --- 场景 B: 系统踢人 ---
        if (roomStatus.containsKey(HighMessageType.SYSTEM_KICK)) {
          final kickMsg = roomStatus[HighMessageType.SYSTEM_KICK]!;
          _handleGlobalKick(
            kickMsg.content ?? "Your account has been logged in elsewhere.",
          );
        }
      }
    });

    return MaterialApp.router(
      title: '记事本客户端',
      routerConfig: ref.watch(routerProvider),
      theme: ref.watch(appThemeProvider),
      builder: BotToastInit(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }

  void _showIncomingCallDialog(HighMessage invite) {
    // 这里可以使用 BotToast 或者 Navigator 跳转到专门的通话接听页
    BotToast.showWidget(
      key: UniqueKey(),
      toastBuilder: (cancel) => Text("识别到电话邀请：${invite.senderId}")
    );
  }

  void _handleGlobalKick(String reason) {
    // 1. 弹窗提示
    BotToast.showSimpleNotification(title: "下线通知", subTitle: reason);
    // 2. 登出逻辑
    // ref.read(authControllerProvider.notifier).logout();
  }
}

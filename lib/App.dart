import 'package:anoxia/features/chat/presentation/call/global_call_overlay.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// 应用根组件
///
/// 负责：
/// - 初始化系统事件服务
/// - 桌面端托盘/窗口管理
/// - 移动端角标监听
/// - 主题/多语言配置
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WindowListener, TrayListener {
  /// 未读消息角标订阅（仅移动端）
  ProviderSubscription<int>? _unreadBadgeSubscription;

  @override
  void initState() {
    super.initState();
    // 启动系统事件监听服务（禁言/封禁/解散等事件分发入口）
    ref.read(systemEventServiceProvider);

    // 桌面端：初始化托盘和窗口事件监听
    if (DeviceUtil.isRealDesktop()) {
      _initTray();
      windowManager.setPreventClose(true);
      windowManager.addListener(this);
      trayManager.addListener(this);
    }

    // 移动端：监听未读数量，更新应用角标
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
    await trayManager.setToolTip('anoxia');

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
    final appTheme = ref.watch(appThemeProvider);
    final isDark = appTheme.brightness == Brightness.dark;
    // 获取全局通话会话状态
    final session = ref.watch(mobileCallSessionControllerProvider);

    /// 手机系统栏适配：根据当前主题调整状态栏和导航栏图标颜色
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    // 初始化 BotToast
    final botToastBuilder = BotToastInit();

    return MaterialApp.router(
      title: 'Anoxia',
      routerConfig: ref.watch(routerProvider),
      theme: appTheme,
      builder: (context, child) {
        // 先让 BotToast 包裹路由子节点
        Widget content = botToastBuilder(context, child);

        // 如果是 Android 端且存在活跃的通话 session，则使用 Stack 在顶层覆盖通话视图
        if (DeviceUtil.isAndroid() && session != null) {
          content = Stack(
            children: [
              content, // 底层：正常的应用路由页面（聊天列表、个人中心等，生命周期完全正常）
              // 顶层：大厂全功能全局通话浮层（内部自适应全屏/小窗/PiP）
              const GlobalCallOverlay(),
            ],
          );
        }

        return content;
      },
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

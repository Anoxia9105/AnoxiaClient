import 'package:anoxia/features/chat/presentation/call/call_invitation_overlay.dart';
import 'package:anoxia/features/chat/presentation/call/global_call_overlay.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
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
  /// 未读消息角标订阅（移动端应用图标、macOS Dock、Windows 任务栏）
  ProviderSubscription<int>? _unreadBadgeSubscription;
  ProviderSubscription<int>? _callThemeSubscription;
  ProviderSubscription<ThemeData>? _systemUiSubscription;
  final TransitionBuilder _botToastBuilder = BotToastInit();

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
      _callThemeSubscription = ref.listenManual<int>(themeIndexProvider, (
        previous,
        next,
      ) {
        if (previous == next) return;
        if (ref.read(callWindowControllerProvider) == null) return;
        ref
            .read(callWindowControllerProvider.notifier)
            .updateSettings(themeIndex: next);
      });
    }

    // 移动端：监听未读数量，更新应用角标
    if (DeviceUtil.isRealMobile()) {
      _systemUiSubscription = ref.listenManual<ThemeData>(
        appThemeProvider,
        (previous, next) => _applySystemUiStyle(next.brightness),
        fireImmediately: true,
      );
    }

    // Mobile/macOS use the app icon badge; Windows uses a taskbar overlay icon.
    if (DeviceUtil.isRealMobile() ||
        DeviceUtil.isMacOS() ||
        DeviceUtil.isWindows()) {
      _unreadBadgeSubscription = ref.listenManual<int>(
        totalUnreadCountProvider,
        (previous, next) {
          NotificationHelper().updateUnreadBadge(next);
        },
        fireImmediately: true,
      );
    }
  }

  @override
  void dispose() {
    _unreadBadgeSubscription?.close();
    _callThemeSubscription?.close();
    _systemUiSubscription?.close();

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

  void _applySystemUiStyle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
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
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final appTheme = ref.watch(appThemeProvider);

    return MaterialApp.router(
      title: 'Anoxia',
      routerConfig: ref.watch(routerProvider),
      theme: appTheme,
      builder: (context, child) {
        // 先让 BotToast 包裹路由子节点
        final content = _botToastBuilder(context, child);
        return _AppOverlays(child: content);
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

class _AppOverlays extends ConsumerWidget {
  const _AppOverlays({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMobileCall = ref.watch(
      mobileCallSessionControllerProvider.select((session) => session != null),
    );
    return Stack(
      children: [
        child,
        if (DeviceUtil.isAndroid() && hasMobileCall) const GlobalCallOverlay(),
        const Positioned.fill(child: CallInvitationOverlay()),
      ],
    );
  }
}

import 'dart:async';

import 'package:anoxia/features/chat/presentation/call/call_invitation_overlay.dart';
import 'package:anoxia/features/chat/presentation/call/global_call_overlay.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/platform/shims/tray_manager_shim.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';

import 'common/constants/storage_keys.dart';
import 'common/utils/device_util.dart';
import 'common/utils/sp_util.dart';
import 'common/widgets/toast.dart';
import 'framework/provider/setting/general_settings_provider.dart';
import 'framework/core/app_globals.dart';
import 'framework/domain/user_info.dart';
import 'framework/provider/auth/auth_controller.dart';
import 'framework/provider/chat/room/room_list_service.dart';
import 'framework/provider/router/router.dart';
import 'framework/provider/chat/message/system_event_service.dart';
import 'framework/provider/chat/message/system_message_service.dart';
import 'framework/provider/ws/ws_controller.dart';
import 'gen/assets.gen.dart';
import 'framework/core/notification_helper.dart';

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
  ProviderSubscription<CallInvitationState?>? _callInvitationSubscription;
  ProviderSubscription<AsyncValue<UserInfo?>>? _authLogoutSubscription;
  final TransitionBuilder _botToastBuilder = BotToastInit();

  @override
  void initState() {
    super.initState();
    // 启动系统事件监听服务（禁言/封禁/解散等事件分发入口）
    ref.read(systemEventServiceProvider);

    // 启动系统消息监听服务（房间通话开始/结束等桌面通知的发送方）
    ref.read(systemMessageServiceProvider);

    // 桌面端：初始化托盘和窗口事件监听
    if (DeviceUtil.isRealDesktop()) {
      _initTray();
      final minimizeToTray = SPUtil.instance.getBool(StorageKeys.windowMinimizeToTray, defValue: true) ?? true;
      windowManager.setPreventClose(minimizeToTray);
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
      ref.listenManual<bool>(windowMinimizeToTrayProvider, (previous, next) {
        windowManager.setPreventClose(next);
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

    _callInvitationSubscription = ref.listenManual<CallInvitationState?>(
      callInvitationControllerProvider,
      (previous, next) {
        // 退出来电态即关闭相关来电系统通知（桌面/移动统一处理，避免接听后残留）。
        if (previous != null &&
            previous.phase == CallInvitationPhase.incoming) {
          final shouldCancel =
              next == null ||
              next.inviteId != previous.inviteId ||
              next.phase != CallInvitationPhase.incoming;
          if (shouldCancel) {
            unawaited(
              NotificationHelper().cancelIncomingCall(previous.inviteId),
            );
          }
        }
        // 仅桌面端本地触发来电系统通知（移动端由 JPush 后台推送 + 前台顶部横幅负责）。
        if (!DeviceUtil.isRealDesktop()) return;
        if (next?.phase != CallInvitationPhase.incoming) return;
        final invitation = next!;
        final displayName = invitation.isGroup
            ? invitation.title.trim()
            : (invitation.callerName.trim().isNotEmpty
                  ? invitation.callerName.trim()
                  : invitation.title.trim());
        final mediaLabel = invitation.initialMedia.value == 'video'
            ? 'call_media_video'.tr()
            : 'call_media_audio'.tr();
        final body =
            invitation.isGroup && invitation.callerName.trim().isNotEmpty
            ? 'call_invitation_group_body'.tr(
                args: [invitation.callerName.trim(), mediaLabel],
              )
            : 'call_invitation_p2p_body'.tr(args: [mediaLabel]);
        unawaited(
          NotificationHelper().showIncomingCall(
            payload: invitation.toNotificationPayload(),
            title: displayName.isEmpty
                ? 'call_invitation_new_title'.tr()
                : displayName,
            body: body,
            avatarUrl:
                invitation.isGroup && invitation.roomAvatar.trim().isNotEmpty
                ? invitation.roomAvatar
                : invitation.callerAvatar,
          ),
        );
      },
    );

    // 登出时清理残留弹窗：切换账号等以 showDialog/push 形式展示的页面
    // 不随 go_router 重定向自动回收，会遮挡登录页。
    _authLogoutSubscription =
        ref.listenManual<AsyncValue<UserInfo?>>(
      authControllerProvider,
      (previous, next) {
        final wasLoggedIn = previous?.value != null;
        final isLoggedOut = next is AsyncData<UserInfo?> && next.value == null;
        if (!wasLoggedIn || !isLoggedOut) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final nav = appNavigatorKey.currentState;
          if (nav == null) return;
          if (nav.canPop()) {
            nav.popUntil((route) => route.isFirst);
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _unreadBadgeSubscription?.close();
    _callThemeSubscription?.close();
    _systemUiSubscription?.close();
    _callInvitationSubscription?.close();
    _authLogoutSubscription?.close();

    if (DeviceUtil.isRealDesktop()) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
    }
    super.dispose();
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
      unawaited(_exitApplication());
    }
  }

  Future<void> _exitApplication() async {
    try {
      await ref
          .read(wsControllerProvider.notifier)
          .disconnectForLogout()
          .timeout(const Duration(seconds: 1));
    } on TimeoutException {
      // 关闭握手超时也继续退出，服务端会通过心跳超时兜底判定离线。
    }
    await windowManager.setPreventClose(false);
    await windowManager.close();
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
    final textScale = ref.watch(textScaleProvider);
    final reduceMotion = ref.watch(reduceMotionProvider);

    return MaterialApp.router(
      title: 'Anoxia',
      scaffoldMessengerKey: Toast.messengerKey,
      routerConfig: ref.watch(routerProvider),
      theme: appTheme,
      builder: (context, child) {
        // 响应式字号与动效：外层已做 clamp(1.3)，此处叠加用户设置
        final mq = MediaQuery.of(context);
        // ignore: deprecated_member_use
        final scale = (mq.textScaleFactor * textScale).clamp(0.85, 1.45);
        final adjustedMq = mq.copyWith(
          // ignore: deprecated_member_use
          textScaleFactor: scale,
          disableAnimations: reduceMotion || mq.disableAnimations,
        );
        final mediaChild = MediaQuery(
          data: adjustedMq,
          child: child ?? const SizedBox.shrink(),
        );
        // 让 BotToast 包裹路由子节点与全局悬浮层（通话层等），
        // 保证 Toast 气泡（表情/设备菜单等）始终显示在最上层
        final overlays = _AppOverlays(child: mediaChild);
        return _botToastBuilder(context, overlays);
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
        // 移动端（Android/iOS）与 Web：通话会话由全局浮层接管；
        // 桌面端走独立通话窗口，不需要应用内浮层。
        if ((DeviceUtil.isRealMobile() || DeviceUtil.isWeb) && hasMobileCall)
          const GlobalCallOverlay(),
        const Positioned.fill(child: CallInvitationOverlay()),
      ],
    );
  }
}

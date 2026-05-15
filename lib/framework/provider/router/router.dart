import 'dart:convert';

import 'package:anoxia/features/contact/presentation/pages/add_friend_page.dart';
import 'package:anoxia/features/settings/presentation/pages/open_source_licenses_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/detail/image_viewer.dart';
import 'package:anoxia/features/app/presentation/pages/error_page.dart';
import 'package:anoxia/features/app/presentation/pages/login_page.dart';
import 'package:anoxia/features/app/presentation/pages/main_layout_page.dart';
import 'package:anoxia/features/app/presentation/pages/splash_page.dart';
import 'package:anoxia/features/update/presentation/pages/update_page.dart';
import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:anoxia/framework/provider/core/AppUpdateInfo.dart' as core;
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:anoxia/framework/domain/UserInfo.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../logs/talker.dart';
import '../core/app_initializer.dart';

part 'router.g.dart';

final _routerKey = GlobalKey<NavigatorState>(debugLabel: 'routerKey');

/// 路由刷新通知器
///
/// 用于监听认证状态变化并触发路由重定向检查
class RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// 应用路由配置
///
/// 基于 GoRouter 的声明式路由，支持：
/// - 认证状态驱动的重定向
/// - 嵌套路由
/// - 路由守卫
@riverpod
GoRouter router(Ref ref) {
  final refreshNotifier = RouterRefreshNotifier();

  // 监听两个核心状态的变化：应用初始化、认证状态
  ref.listen(appInitializerProvider, (_, _) => refreshNotifier.notify());
  ref.listen(authControllerProvider, (_, _) => refreshNotifier.notify());
  ref.onDispose(refreshNotifier.dispose);

  final router = GoRouter(
    observers: [BotToastNavigatorObserver()],
    navigatorKey: _routerKey,
    refreshListenable: refreshNotifier,
    initialLocation: const SplashRoute().location,
    debugLogDiagnostics: true,
    routes: $appRoutes,
    redirect: (context, state) {
      final initStatus = ref.read(appInitializerProvider);
      final authStatus = ref.read(authControllerProvider);

      final location = state.matchedLocation;
      final isSplash = location == const SplashRoute().location;
      final isLogin = location == const InitLoginRoute().location;

      // 初始化出错时跳转到错误页
      if (initStatus.hasError && location != const ErrorRoute().location) {
        return ErrorRoute(message: initStatus.error.toString()).location;
      }

      if (!initStatus.hasValue) {
        // 已认证用户在 re-init（重新登录后重跑初始化）期间，不打回 Splash
        final isAuthenticated =
            authStatus is AsyncData && authStatus.value != null;
        if (isAuthenticated) {
          return isLogin ? const HomeRoute().location : null;
        }
        return isSplash ? null : const SplashRoute().location;
      }

      // 根据认证状态重定向
      switch (authStatus) {
        case AsyncError():
          return const InitLoginRoute().location;
        case AsyncLoading():
          return null;
        case AsyncData(value: null):
          if (isLogin) return null;
          return const InitLoginRoute().location;
        case AsyncData(value: UserInfo _):
          if (isSplash) return const HomeRoute().location;
          if (isLogin) return const HomeRoute().location;
          return null;
      }
    },
  );

  ref.onDispose(() {
    log.info('[Router] 路由服务销毁');
    router.dispose();
  });

  return router;
}

/// 登录页路由
@TypedGoRoute<InitLoginRoute>(path: '/login')
class InitLoginRoute extends GoRouteData with $InitLoginRoute {
  const InitLoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const LoginPage();
}

/// 首页/主布局路由
@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MainLayoutPage();
}

/// 启动页路由
@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SplashPage();
}

/// 错误页路由
@TypedGoRoute<ErrorRoute>(path: '/error')
class ErrorRoute extends GoRouteData with $ErrorRoute {
  final String? message;
  const ErrorRoute({this.message});

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ErrorPage(message: message);
}

/// 图片预览路由
@TypedGoRoute<ImageMessageDetailRoute>(path: '/imageView')
class ImageMessageDetailRoute extends GoRouteData
    with $ImageMessageDetailRoute {
  final Attachment attachment;
  final String heroTag;
  const ImageMessageDetailRoute({
    required this.attachment,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ImageViewer(attachment: attachment, heroTag: heroTag);
}

/// 添加好友页路由
@TypedGoRoute<AddFriendRoute>(path: '/add-friend')
class AddFriendRoute extends GoRouteData with $AddFriendRoute {
  const AddFriendRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AddFriendPage();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return MaterialPage(key: state.pageKey, child: const AddFriendPage());
  }
}

/// 更新页路由
@TypedGoRoute<UpdateRoute>(path: '/update')
class UpdateRoute extends GoRouteData with $UpdateRoute {
  final bool hasUpdate;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;
  final String minSupportVersion;

  const UpdateRoute({
    required this.hasUpdate,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.forceUpdate,
    required this.minSupportVersion,
  });

  @override
  Widget build(BuildContext context, GoRouterState state) => UpdatePage(
    updateInfo: core.AppUpdateInfo(
      hasUpdate: hasUpdate,
      latestVersion: latestVersion,
      downloadUrl: downloadUrl,
      releaseNotes: releaseNotes,
      forceUpdate: forceUpdate,
      minSupportVersion: minSupportVersion,
    ),
  );
}

/// 开源许可列表页
@TypedGoRoute<OpenSourceLicensesRoute>(path: '/open-source-licenses')
class OpenSourceLicensesRoute extends GoRouteData with $OpenSourceLicensesRoute {
  const OpenSourceLicensesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const OpenSourceLicensesPage();
}

/// 开源许可详情页
@TypedGoRoute<OpenSourceLicenseDetailRoute>(
  path: '/open-source-licenses/detail',
)
class OpenSourceLicenseDetailRoute extends GoRouteData
    with $OpenSourceLicenseDetailRoute {
  final String packageName;
  const OpenSourceLicenseDetailRoute({required this.packageName});

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      OpenSourceLicenseDetailPage(packageName: packageName);
}

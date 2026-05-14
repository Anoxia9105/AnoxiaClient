import 'dart:convert';

import 'package:anoxia/features/contact/presentation/pages/add_friend_page.dart';
import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:anoxia/pages/chat/component/widget/messageRender/detail/ImageViewer.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:anoxia/framework/domain/UserInfo.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/pages/ErrorPage.dart';
import 'package:anoxia/pages/LoginPage.dart';
import 'package:anoxia/pages/MainLayoutPage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../pages/SplashPage.dart';
import '../../logs/talker.dart';
import '../core/app_initializer.dart';

part 'router.g.dart';

final _routerKey = GlobalKey<NavigatorState>(debugLabel: 'routerKey');

// 定义一个简单的代理类
class RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

@riverpod
GoRouter router(Ref ref) {
  final refreshNotifier = RouterRefreshNotifier();

  // 监听两个核心状态的变化
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

      // 如果初始化出错，可以跳到 Error 页
      if (initStatus.hasError && location != const ErrorRoute().location) {
        return ErrorRoute(message: initStatus.error.toString()).location;
      }

      if (!initStatus.hasValue) {
        // 已认证用户在 re-init（重新登录后重跑初始化）期间，不打回 Splash
        // 直接放行到首页，让业务 provider 在后台完成加载
        final isAuthenticated =
            authStatus is AsyncData && authStatus.value != null;
        if (isAuthenticated) {
          return isLogin ? const HomeRoute().location : null;
        }
        return isSplash ? null : const SplashRoute().location;
      }

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
    log.info("[Router] 路由服务销毁");
    router.dispose();
  });

  return router;
}

@TypedGoRoute<InitLoginRoute>(path: '/login')
class InitLoginRoute extends GoRouteData with $InitLoginRoute {
  const InitLoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const LoginPage();
}

@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MainLayoutPage();
}

@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SplashPage();
}

@TypedGoRoute<ErrorRoute>(path: '/error')
class ErrorRoute extends GoRouteData with $ErrorRoute {
  final String? message; // 错误信息
  const ErrorRoute({this.message});

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ErrorPage(message: message);
}

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

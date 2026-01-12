import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notepadclient/framework/domain/UserInfo.dart';
import 'package:notepadclient/framework/provider/auth/auth_controller.dart';
import 'package:notepadclient/pages/ErrorPage.dart';
import 'package:notepadclient/pages/LoginPage.dart';
import 'package:notepadclient/pages/MainLayoutPage.dart';
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
  ref.listen(appInitializerProvider, (_, __) => refreshNotifier.notify());
  ref.listen(authControllerProvider, (_, __) => refreshNotifier.notify());
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
        return isSplash ? null : const SplashRoute().location;
      }

      switch (authStatus) {
        case AsyncError():
          return const InitLoginRoute().location;
        case AsyncLoading():
          return null;
        case AsyncData(value: null):
          if (isSplash) return const InitLoginRoute().location;
          if (isLogin) return null;

          return const SplashRoute().location;
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

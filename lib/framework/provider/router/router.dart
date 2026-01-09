import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notepadclient/pages/ErrorPage.dart';
import 'package:notepadclient/pages/LoginPage.dart';
import 'package:notepadclient/pages/MainLayoutPage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../pages/SplashPage.dart';
import '../../logs/talker.dart';
import '../auth/auth_state_provider.dart';
import '../core/app_initializer.dart';

part 'router.g.dart';

final _routerKey = GlobalKey<NavigatorState>(debugLabel: 'routerKey');

@riverpod
GoRouter router(Ref ref) {
  final auth = ref.watch(authStateProvider);
  final initialization = ref.watch(appInitializerProvider);

  return GoRouter(
    observers: [BotToastNavigatorObserver()],
    navigatorKey: _routerKey,
    initialLocation: const SplashRoute().location, // 直接从 Splash 开始
    debugLogDiagnostics: true,
    routes: $appRoutes,
    redirect: (context, state) {
      final currentLocation = state.matchedLocation;
      log.info("[Router] 当前路径: $currentLocation, 认证状态: ${auth.status}, 初始化状态: $initialization");

      // 如果已经在错误页，不重定向
      if (currentLocation == ErrorRoute().location) {
        return null;
      }

      // 如果已经在登录页，不重定向
      if (currentLocation == InitLoginRoute().location) {
        return null;
      }

      // 根据认证状态进行路由保护
      switch (auth.status) {
        case AuthStatus.initial:
        case AuthStatus.checking:
        // 初始或检查中 -> 停留在 Splash 页
          if (currentLocation != SplashRoute().location) {
            return SplashRoute().location;
          }
          return null;

        case AuthStatus.authenticated:
        // 已认证 -> 如果不在首页，跳转到首页
          if (currentLocation == SplashRoute().location ||
              currentLocation == InitLoginRoute().location) {
            return HomeRoute().location;
          }
          return null;

        case AuthStatus.unauthenticated:
        // 未认证 -> 跳转到登录页
          if (currentLocation != InitLoginRoute().location) {
            return InitLoginRoute().location;
          }
          return null;

        case AuthStatus.error:
        // 错误 -> 跳转到错误页
          if (currentLocation != ErrorRoute().location) {
            return ErrorRoute(message: auth.errorMessage).location;
          }
          return null;
      }
    },
  );
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
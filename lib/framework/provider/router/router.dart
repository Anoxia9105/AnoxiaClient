import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notepadclient/pages/LoginPage.dart';
import 'package:notepadclient/pages/MainLayoutPage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../pages/SplashPage.dart';
import '../../logs/talker.dart';
import '../auth/auth_state_provider.dart';

part 'router.g.dart';

final _routerKey = GlobalKey<NavigatorState>(debugLabel: 'routerKey');

@riverpod
GoRouter router(Ref ref) {
  //登录状态
  final status = ref.watch(authStateProvider);
  final router = GoRouter(
    observers: [BotToastNavigatorObserver()],
    navigatorKey: _routerKey,
    initialLocation: const HomeRoute().location,
    debugLogDiagnostics: true,
    routes: $appRoutes,
    redirect: (context, state) {
      log.info("==========================================================$status");
      // 初始状态不重定向，等待认证结果
      if (status == AuthStatus.initial) return SplashRoute().location;

      final isLoggedIn = status == AuthStatus.authenticated;
      final isLoginPage = state.matchedLocation == InitLoginRoute().location;

      // 如果未登录且不在登录页，重定向到登录页
      if (!isLoggedIn && !isLoginPage) {
        log.info("用户未登录，重定向到登录页");
        return InitLoginRoute().location;
      }
      // 如果已登录且在登录页，重定向到首页
      if (isLoggedIn && isLoginPage) {
        log.info("用户已登录，重定向到首页");
        return "/";
      }
      return null;
    },
  );
  ref.onDispose(router.dispose);

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
  Widget build(BuildContext context, GoRouterState state) => const MainLayoutPage();
}



@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends GoRouteData with $SplashRoute{
  const SplashRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const SplashPage();
}
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $initLoginRoute,
  $homeRoute,
  $splashRoute,
  $errorRoute,
  $imageMessageDetailRoute,
  $addFriendRoute,
  $updateRoute,
  $openSourceLicensesRoute,
  $openSourceLicenseDetailRoute,
];

RouteBase get $initLoginRoute =>
    GoRouteData.$route(path: '/login', factory: $InitLoginRoute._fromState);

mixin $InitLoginRoute on GoRouteData {
  static InitLoginRoute _fromState(GoRouterState state) =>
      const InitLoginRoute();

  @override
  String get location => GoRouteData.$location('/login');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $homeRoute =>
    GoRouteData.$route(path: '/', factory: $HomeRoute._fromState);

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $splashRoute =>
    GoRouteData.$route(path: '/splash', factory: $SplashRoute._fromState);

mixin $SplashRoute on GoRouteData {
  static SplashRoute _fromState(GoRouterState state) => const SplashRoute();

  @override
  String get location => GoRouteData.$location('/splash');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $errorRoute =>
    GoRouteData.$route(path: '/error', factory: $ErrorRoute._fromState);

mixin $ErrorRoute on GoRouteData {
  static ErrorRoute _fromState(GoRouterState state) =>
      ErrorRoute(message: state.uri.queryParameters['message']);

  ErrorRoute get _self => this as ErrorRoute;

  @override
  String get location => GoRouteData.$location(
    '/error',
    queryParams: {if (_self.message != null) 'message': _self.message},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $imageMessageDetailRoute => GoRouteData.$route(
  path: '/imageView',
  factory: $ImageMessageDetailRoute._fromState,
);

mixin $ImageMessageDetailRoute on GoRouteData {
  static ImageMessageDetailRoute _fromState(GoRouterState state) =>
      ImageMessageDetailRoute(
        attachment: (String json0) {
          return Attachment.fromJson(jsonDecode(json0) as Map<String, dynamic>);
        }(state.uri.queryParameters['attachment']!),
        heroTag: state.uri.queryParameters['hero-tag']!,
      );

  ImageMessageDetailRoute get _self => this as ImageMessageDetailRoute;

  @override
  String get location => GoRouteData.$location(
    '/imageView',
    queryParams: {
      'attachment': jsonEncode(_self.attachment.toJson()),
      'hero-tag': _self.heroTag,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $addFriendRoute => GoRouteData.$route(
  path: '/add-friend',
  factory: $AddFriendRoute._fromState,
);

mixin $AddFriendRoute on GoRouteData {
  static AddFriendRoute _fromState(GoRouterState state) =>
      const AddFriendRoute();

  @override
  String get location => GoRouteData.$location('/add-friend');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $updateRoute =>
    GoRouteData.$route(path: '/update', factory: $UpdateRoute._fromState);

mixin $UpdateRoute on GoRouteData {
  static UpdateRoute _fromState(GoRouterState state) => UpdateRoute(
    hasUpdate: _$boolConverter(state.uri.queryParameters['has-update']!),
    latestVersion: state.uri.queryParameters['latest-version']!,
    downloadUrl: state.uri.queryParameters['download-url']!,
    releaseNotes: state.uri.queryParameters['release-notes']!,
    forceUpdate: _$boolConverter(state.uri.queryParameters['force-update']!),
    minSupportVersion: state.uri.queryParameters['min-support-version']!,
  );

  UpdateRoute get _self => this as UpdateRoute;

  @override
  String get location => GoRouteData.$location(
    '/update',
    queryParams: {
      'has-update': _self.hasUpdate.toString(),
      'latest-version': _self.latestVersion,
      'download-url': _self.downloadUrl,
      'release-notes': _self.releaseNotes,
      'force-update': _self.forceUpdate.toString(),
      'min-support-version': _self.minSupportVersion,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

bool _$boolConverter(String value) {
  switch (value) {
    case 'true':
      return true;
    case 'false':
      return false;
    default:
      throw UnsupportedError('Cannot convert "$value" into a bool.');
  }
}

RouteBase get $openSourceLicensesRoute => GoRouteData.$route(
  path: '/open-source-licenses',
  factory: $OpenSourceLicensesRoute._fromState,
);

mixin $OpenSourceLicensesRoute on GoRouteData {
  static OpenSourceLicensesRoute _fromState(GoRouterState state) =>
      const OpenSourceLicensesRoute();

  @override
  String get location => GoRouteData.$location('/open-source-licenses');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $openSourceLicenseDetailRoute => GoRouteData.$route(
  path: '/open-source-licenses/detail',
  factory: $OpenSourceLicenseDetailRoute._fromState,
);

mixin $OpenSourceLicenseDetailRoute on GoRouteData {
  static OpenSourceLicenseDetailRoute _fromState(GoRouterState state) =>
      OpenSourceLicenseDetailRoute(
        packageName: state.uri.queryParameters['package-name']!,
      );

  OpenSourceLicenseDetailRoute get _self =>
      this as OpenSourceLicenseDetailRoute;

  @override
  String get location => GoRouteData.$location(
    '/open-source-licenses/detail',
    queryParams: {'package-name': _self.packageName},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 应用路由配置
///
/// 基于 GoRouter 的声明式路由，支持：
/// - 认证状态驱动的重定向
/// - 嵌套路由
/// - 路由守卫

@ProviderFor(router)
const routerProvider = RouterProvider._();

/// 应用路由配置
///
/// 基于 GoRouter 的声明式路由，支持：
/// - 认证状态驱动的重定向
/// - 嵌套路由
/// - 路由守卫

final class RouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// 应用路由配置
  ///
  /// 基于 GoRouter 的声明式路由，支持：
  /// - 认证状态驱动的重定向
  /// - 嵌套路由
  /// - 路由守卫
  const RouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return router(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerHash() => r'c5a7b978b5f179dfa7f9dc8b1f0ba0a4827c21b5';

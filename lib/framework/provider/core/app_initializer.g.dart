// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_initializer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 应用初始化协调器
///
/// 负责管理应用启动时的初始化序列：
/// 1. 挂载基础服务
/// 2. 等待认证模块就绪
/// 3. 执行业务数据预加载
///
/// 采用 keepAlive 模式，确保初始化结果在全局共享。

@ProviderFor(AppInitializer)
const appInitializerProvider = AppInitializerProvider._();

/// 应用初始化协调器
///
/// 负责管理应用启动时的初始化序列：
/// 1. 挂载基础服务
/// 2. 等待认证模块就绪
/// 3. 执行业务数据预加载
///
/// 采用 keepAlive 模式，确保初始化结果在全局共享。
final class AppInitializerProvider
    extends $AsyncNotifierProvider<AppInitializer, bool> {
  /// 应用初始化协调器
  ///
  /// 负责管理应用启动时的初始化序列：
  /// 1. 挂载基础服务
  /// 2. 等待认证模块就绪
  /// 3. 执行业务数据预加载
  ///
  /// 采用 keepAlive 模式，确保初始化结果在全局共享。
  const AppInitializerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appInitializerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appInitializerHash();

  @$internal
  @override
  AppInitializer create() => AppInitializer();
}

String _$appInitializerHash() => r'88a40e80bfe7c7d88f1dce31e478f57e0dc977e1';

/// 应用初始化协调器
///
/// 负责管理应用启动时的初始化序列：
/// 1. 挂载基础服务
/// 2. 等待认证模块就绪
/// 3. 执行业务数据预加载
///
/// 采用 keepAlive 模式，确保初始化结果在全局共享。

abstract class _$AppInitializer extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

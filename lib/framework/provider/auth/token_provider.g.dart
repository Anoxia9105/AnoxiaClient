// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Token 内存缓存 Provider
///
/// 登录成功后更新，登出时清空。
/// 采用 keepAlive 保持常驻，避免重复初始化。
/// 与 [TokenManager] 的区别：此 Provider 提供响应式状态，
/// [TokenManager] 提供持久化能力。

@ProviderFor(TokenCache)
const tokenCacheProvider = TokenCacheProvider._();

/// Token 内存缓存 Provider
///
/// 登录成功后更新，登出时清空。
/// 采用 keepAlive 保持常驻，避免重复初始化。
/// 与 [TokenManager] 的区别：此 Provider 提供响应式状态，
/// [TokenManager] 提供持久化能力。
final class TokenCacheProvider extends $NotifierProvider<TokenCache, String?> {
  /// Token 内存缓存 Provider
  ///
  /// 登录成功后更新，登出时清空。
  /// 采用 keepAlive 保持常驻，避免重复初始化。
  /// 与 [TokenManager] 的区别：此 Provider 提供响应式状态，
  /// [TokenManager] 提供持久化能力。
  const TokenCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tokenCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tokenCacheHash();

  @$internal
  @override
  TokenCache create() => TokenCache();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$tokenCacheHash() => r'4580de6d96a3cf08d6925ddf92a16c2097987395';

/// Token 内存缓存 Provider
///
/// 登录成功后更新，登出时清空。
/// 采用 keepAlive 保持常驻，避免重复初始化。
/// 与 [TokenManager] 的区别：此 Provider 提供响应式状态，
/// [TokenManager] 提供持久化能力。

abstract class _$TokenCache extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

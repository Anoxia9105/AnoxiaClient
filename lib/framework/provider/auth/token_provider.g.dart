// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Token Provider - 用于在内存中缓存 token
/// 登录成功后更新，登出时清空
/// 避免每次请求都从 TokenManager 读取

@ProviderFor(TokenCache)
const tokenCacheProvider = TokenCacheProvider._();

/// Token Provider - 用于在内存中缓存 token
/// 登录成功后更新，登出时清空
/// 避免每次请求都从 TokenManager 读取
final class TokenCacheProvider extends $NotifierProvider<TokenCache, String?> {
  /// Token Provider - 用于在内存中缓存 token
  /// 登录成功后更新，登出时清空
  /// 避免每次请求都从 TokenManager 读取
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

/// Token Provider - 用于在内存中缓存 token
/// 登录成功后更新，登出时清空
/// 避免每次请求都从 TokenManager 读取

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

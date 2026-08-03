// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 认证状态管理器
///
/// 负责用户登录、登出和会话恢复的核心 Provider。
/// 与 [TokenCache] 配合实现 Token 的内存缓存和持久化存储。

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// 认证状态管理器
///
/// 负责用户登录、登出和会话恢复的核心 Provider。
/// 与 [TokenCache] 配合实现 Token 的内存缓存和持久化存储。
final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, UserInfo?> {
  /// 认证状态管理器
  ///
  /// 负责用户登录、登出和会话恢复的核心 Provider。
  /// 与 [TokenCache] 配合实现 Token 的内存缓存和持久化存储。
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();
}

String _$authControllerHash() => r'de629a43d4ef59b50169c9a4883af071f1fbcc2f';

/// 认证状态管理器
///
/// 负责用户登录、登出和会话恢复的核心 Provider。
/// 与 [TokenCache] 配合实现 Token 的内存缓存和持久化存储。

abstract class _$AuthController extends $AsyncNotifier<UserInfo?> {
  FutureOr<UserInfo?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UserInfo?>, UserInfo?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserInfo?>, UserInfo?>,
              AsyncValue<UserInfo?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 获取验证码
///
/// 每次调用都会请求新的验证码，返回 UUID 和 Base64 图片

@ProviderFor(getCaptcha)
final getCaptchaProvider = GetCaptchaProvider._();

/// 获取验证码
///
/// 每次调用都会请求新的验证码，返回 UUID 和 Base64 图片

final class GetCaptchaProvider
    extends
        $FunctionalProvider<
          AsyncValue<CaptchaModel>,
          CaptchaModel,
          FutureOr<CaptchaModel>
        >
    with $FutureModifier<CaptchaModel>, $FutureProvider<CaptchaModel> {
  /// 获取验证码
  ///
  /// 每次调用都会请求新的验证码，返回 UUID 和 Base64 图片
  GetCaptchaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getCaptchaProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getCaptchaHash();

  @$internal
  @override
  $FutureProviderElement<CaptchaModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CaptchaModel> create(Ref ref) {
    return getCaptcha(ref);
  }
}

String _$getCaptchaHash() => r'61a5192da54948445de95278f282ca93dfd07ab4';

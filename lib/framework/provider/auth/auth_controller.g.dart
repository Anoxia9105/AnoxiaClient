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
const authControllerProvider = AuthControllerProvider._();

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
  const AuthControllerProvider._()
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

String _$authControllerHash() => r'0af1961be0ace446c975d348bb2a578f38419a97';

/// 认证状态管理器
///
/// 负责用户登录、登出和会话恢复的核心 Provider。
/// 与 [TokenCache] 配合实现 Token 的内存缓存和持久化存储。

abstract class _$AuthController extends $AsyncNotifier<UserInfo?> {
  FutureOr<UserInfo?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<UserInfo?>, UserInfo?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserInfo?>, UserInfo?>,
              AsyncValue<UserInfo?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// 获取验证码
///
/// 每次调用都会请求新的验证码，返回 UUID 和 Base64 图片

@ProviderFor(getCaptcha)
const getCaptchaProvider = GetCaptchaProvider._();

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
  const GetCaptchaProvider._()
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

String _$getCaptchaHash() => r'7c85dd7a0f8b8e2d1cbcf04d4c794e728c2d3d18';

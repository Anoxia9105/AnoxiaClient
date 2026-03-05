// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthController)
const authControllerProvider = AuthControllerProvider._();

final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, UserInfo?> {
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

String _$authControllerHash() => r'e753b8d71c0ad9339a9b25fbf031a6d845c7d771';

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

@ProviderFor(getCaptcha)
const getCaptchaProvider = GetCaptchaProvider._();

/// 获取验证码

final class GetCaptchaProvider
    extends
        $FunctionalProvider<
          AsyncValue<CaptchaModel>,
          CaptchaModel,
          FutureOr<CaptchaModel>
        >
    with $FutureModifier<CaptchaModel>, $FutureProvider<CaptchaModel> {
  /// 获取验证码
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

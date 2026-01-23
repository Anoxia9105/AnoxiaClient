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

String _$authControllerHash() => r'567c51bf685d6b7fa50cba5e254aeb35d56f3cf9';

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

String _$getCaptchaHash() => r'97d4ceb26b41b94b922637db017c94f50a4d05fb';

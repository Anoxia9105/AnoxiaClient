// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authService)
const authServiceProvider = AuthServiceProvider._();

final class AuthServiceProvider
    extends $FunctionalProvider<AuthService, AuthService, AuthService>
    with $Provider<AuthService> {
  const AuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authServiceHash();

  @$internal
  @override
  $ProviderElement<AuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthService create(Ref ref) {
    return authService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthService>(value),
    );
  }
}

String _$authServiceHash() => r'82398d9f38c720e4ddf6b218248f15089fd4f178';

@ProviderFor(captcha)
const captchaProvider = CaptchaProvider._();

final class CaptchaProvider
    extends
        $FunctionalProvider<
          AsyncValue<CaptchaModel>,
          CaptchaModel,
          FutureOr<CaptchaModel>
        >
    with $FutureModifier<CaptchaModel>, $FutureProvider<CaptchaModel> {
  const CaptchaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captchaProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captchaHash();

  @$internal
  @override
  $FutureProviderElement<CaptchaModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CaptchaModel> create(Ref ref) {
    return captcha(ref);
  }
}

String _$captchaHash() => r'4ec8881cb3a52a028878831e79a1116f6b1f2c1a';

@ProviderFor(userInfo)
const userInfoProvider = UserInfoProvider._();

final class UserInfoProvider
    extends
        $FunctionalProvider<AsyncValue<UserInfo>, UserInfo, FutureOr<UserInfo>>
    with $FutureModifier<UserInfo>, $FutureProvider<UserInfo> {
  const UserInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userInfoHash();

  @$internal
  @override
  $FutureProviderElement<UserInfo> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<UserInfo> create(Ref ref) {
    return userInfo(ref);
  }
}

String _$userInfoHash() => r'44a718321a523c622c2a96819bc260c3cf3c01b4';

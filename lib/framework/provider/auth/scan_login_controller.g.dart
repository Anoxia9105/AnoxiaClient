// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_login_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 扫码登录控制器（桌面/Web 展示端）
///
/// 负责创建扫码登录会话并以 2s 间隔轮询状态：
/// - 手机确认后拿到 token 直接完成登录（复用 [AuthController.loginByScanToken]）
/// - 会话过期时自动重新创建二维码
/// - 页面销毁时自动取消轮询

@ProviderFor(ScanLoginController)
final scanLoginControllerProvider = ScanLoginControllerProvider._();

/// 扫码登录控制器（桌面/Web 展示端）
///
/// 负责创建扫码登录会话并以 2s 间隔轮询状态：
/// - 手机确认后拿到 token 直接完成登录（复用 [AuthController.loginByScanToken]）
/// - 会话过期时自动重新创建二维码
/// - 页面销毁时自动取消轮询
final class ScanLoginControllerProvider
    extends $AsyncNotifierProvider<ScanLoginController, ScanLoginSession?> {
  /// 扫码登录控制器（桌面/Web 展示端）
  ///
  /// 负责创建扫码登录会话并以 2s 间隔轮询状态：
  /// - 手机确认后拿到 token 直接完成登录（复用 [AuthController.loginByScanToken]）
  /// - 会话过期时自动重新创建二维码
  /// - 页面销毁时自动取消轮询
  ScanLoginControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanLoginControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanLoginControllerHash();

  @$internal
  @override
  ScanLoginController create() => ScanLoginController();
}

String _$scanLoginControllerHash() =>
    r'c88d06167e89d4ef7c825719a3b622ccc267ada5';

/// 扫码登录控制器（桌面/Web 展示端）
///
/// 负责创建扫码登录会话并以 2s 间隔轮询状态：
/// - 手机确认后拿到 token 直接完成登录（复用 [AuthController.loginByScanToken]）
/// - 会话过期时自动重新创建二维码
/// - 页面销毁时自动取消轮询

abstract class _$ScanLoginController extends $AsyncNotifier<ScanLoginSession?> {
  FutureOr<ScanLoginSession?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ScanLoginSession?>, ScanLoginSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ScanLoginSession?>, ScanLoginSession?>,
              AsyncValue<ScanLoginSession?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_window_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 通话窗口控制器
///
/// 负责桌面端通话窗口的创建、管理、设置同步和通话成员邀请。
/// 通过 [WindowController] 实现多窗口通信。

@ProviderFor(CallWindowController)
final callWindowControllerProvider = CallWindowControllerProvider._();

/// 通话窗口控制器
///
/// 负责桌面端通话窗口的创建、管理、设置同步和通话成员邀请。
/// 通过 [WindowController] 实现多窗口通信。
final class CallWindowControllerProvider
    extends $NotifierProvider<CallWindowController, WindowController?> {
  /// 通话窗口控制器
  ///
  /// 负责桌面端通话窗口的创建、管理、设置同步和通话成员邀请。
  /// 通过 [WindowController] 实现多窗口通信。
  CallWindowControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callWindowControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callWindowControllerHash();

  @$internal
  @override
  CallWindowController create() => CallWindowController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WindowController? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WindowController?>(value),
    );
  }
}

String _$callWindowControllerHash() =>
    r'f9e8fbe56f80951cf2a7886dab1bc98cef5f5f40';

/// 通话窗口控制器
///
/// 负责桌面端通话窗口的创建、管理、设置同步和通话成员邀请。
/// 通过 [WindowController] 实现多窗口通信。

abstract class _$CallWindowController extends $Notifier<WindowController?> {
  WindowController? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WindowController?, WindowController?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WindowController?, WindowController?>,
              WindowController?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'layout_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 布局状态管理器
///
/// 控制桌面端的侧边栏状态、当前选中页面索引等。

@ProviderFor(LayoutController)
const layoutControllerProvider = LayoutControllerProvider._();

/// 布局状态管理器
///
/// 控制桌面端的侧边栏状态、当前选中页面索引等。
final class LayoutControllerProvider
    extends $NotifierProvider<LayoutController, LayoutState> {
  /// 布局状态管理器
  ///
  /// 控制桌面端的侧边栏状态、当前选中页面索引等。
  const LayoutControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'layoutControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$layoutControllerHash();

  @$internal
  @override
  LayoutController create() => LayoutController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LayoutState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LayoutState>(value),
    );
  }
}

String _$layoutControllerHash() => r'738c475993868425a29c543744049c8164440f0d';

/// 布局状态管理器
///
/// 控制桌面端的侧边栏状态、当前选中页面索引等。

abstract class _$LayoutController extends $Notifier<LayoutState> {
  LayoutState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<LayoutState, LayoutState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LayoutState, LayoutState>,
              LayoutState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

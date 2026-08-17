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
final layoutControllerProvider = LayoutControllerProvider._();

/// 布局状态管理器
///
/// 控制桌面端的侧边栏状态、当前选中页面索引等。
final class LayoutControllerProvider
    extends $NotifierProvider<LayoutController, LayoutState> {
  /// 布局状态管理器
  ///
  /// 控制桌面端的侧边栏状态、当前选中页面索引等。
  LayoutControllerProvider._()
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

String _$layoutControllerHash() => r'0f42c756014f5f08229a6b25033d69506f8f30bc';

/// 布局状态管理器
///
/// 控制桌面端的侧边栏状态、当前选中页面索引等。

abstract class _$LayoutController extends $Notifier<LayoutState> {
  LayoutState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LayoutState, LayoutState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LayoutState, LayoutState>,
              LayoutState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'layout_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LayoutController)
const layoutControllerProvider = LayoutControllerProvider._();

final class LayoutControllerProvider
    extends $NotifierProvider<LayoutController, LayoutState> {
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

String _$layoutControllerHash() => r'8d559725f3c56f758b1dcef46e7af7a238a035ea';

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

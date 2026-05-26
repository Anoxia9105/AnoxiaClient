// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DesktopSearchController)
final desktopSearchControllerProvider = DesktopSearchControllerProvider._();

final class DesktopSearchControllerProvider
    extends $NotifierProvider<DesktopSearchController, SearchResultState> {
  DesktopSearchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopSearchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopSearchControllerHash();

  @$internal
  @override
  DesktopSearchController create() => DesktopSearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchResultState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchResultState>(value),
    );
  }
}

String _$desktopSearchControllerHash() =>
    r'b6b31f57a7cb0809808f19177cf08b80a902942e';

abstract class _$DesktopSearchController extends $Notifier<SearchResultState> {
  SearchResultState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SearchResultState, SearchResultState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchResultState, SearchResultState>,
              SearchResultState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

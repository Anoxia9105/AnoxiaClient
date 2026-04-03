// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_panel_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HistoryPanelNotifier)
const historyPanelProvider = HistoryPanelNotifierProvider._();

final class HistoryPanelNotifierProvider
    extends $NotifierProvider<HistoryPanelNotifier, bool> {
  const HistoryPanelNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyPanelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyPanelNotifierHash();

  @$internal
  @override
  HistoryPanelNotifier create() => HistoryPanelNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$historyPanelNotifierHash() =>
    r'537fce285e7da1241adfdbf5a914ffba0e8cb774';

abstract class _$HistoryPanelNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_window_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CallWindowController)
const callWindowControllerProvider = CallWindowControllerProvider._();

final class CallWindowControllerProvider
    extends $NotifierProvider<CallWindowController, WindowController?> {
  const CallWindowControllerProvider._()
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
    r'6ee3dc9316449225cddba8c2ca65a3f1a951dfed';

abstract class _$CallWindowController extends $Notifier<WindowController?> {
  WindowController? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<WindowController?, WindowController?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WindowController?, WindowController?>,
              WindowController?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

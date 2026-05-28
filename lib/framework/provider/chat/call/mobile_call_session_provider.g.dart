// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mobile_call_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MobileCallSessionController)
final mobileCallSessionControllerProvider =
    MobileCallSessionControllerProvider._();

final class MobileCallSessionControllerProvider
    extends $NotifierProvider<MobileCallSessionController, MobileCallSession?> {
  MobileCallSessionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mobileCallSessionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mobileCallSessionControllerHash();

  @$internal
  @override
  MobileCallSessionController create() => MobileCallSessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MobileCallSession? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MobileCallSession?>(value),
    );
  }
}

String _$mobileCallSessionControllerHash() =>
    r'd1ddb718e742fa6810504958ab425fe1502ee906';

abstract class _$MobileCallSessionController
    extends $Notifier<MobileCallSession?> {
  MobileCallSession? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MobileCallSession?, MobileCallSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MobileCallSession?, MobileCallSession?>,
              MobileCallSession?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

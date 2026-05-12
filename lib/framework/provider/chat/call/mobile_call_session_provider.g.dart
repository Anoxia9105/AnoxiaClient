// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mobile_call_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MobileCallSessionController)
const mobileCallSessionControllerProvider =
    MobileCallSessionControllerProvider._();

final class MobileCallSessionControllerProvider
    extends $NotifierProvider<MobileCallSessionController, MobileCallSession?> {
  const MobileCallSessionControllerProvider._()
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
    r'4863a4a05f5f6364385e931e793e947009e29fdc';

abstract class _$MobileCallSessionController
    extends $Notifier<MobileCallSession?> {
  MobileCallSession? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MobileCallSession?, MobileCallSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MobileCallSession?, MobileCallSession?>,
              MobileCallSession?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_connection_warmup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(callConnectionWarmup)
final callConnectionWarmupProvider = CallConnectionWarmupProvider._();

final class CallConnectionWarmupProvider
    extends
        $FunctionalProvider<
          CallConnectionWarmup,
          CallConnectionWarmup,
          CallConnectionWarmup
        >
    with $Provider<CallConnectionWarmup> {
  CallConnectionWarmupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callConnectionWarmupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callConnectionWarmupHash();

  @$internal
  @override
  $ProviderElement<CallConnectionWarmup> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CallConnectionWarmup create(Ref ref) {
    return callConnectionWarmup(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CallConnectionWarmup value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CallConnectionWarmup>(value),
    );
  }
}

String _$callConnectionWarmupHash() =>
    r'102e11cd8d7ac694eb016f08ee37ae9e9e87f457';

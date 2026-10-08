// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forwarding_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ForwardingController)
final forwardingControllerProvider = ForwardingControllerProvider._();

final class ForwardingControllerProvider
    extends
        $NotifierProvider<ForwardingController, AsyncValue<ForwardResult?>> {
  ForwardingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forwardingControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forwardingControllerHash();

  @$internal
  @override
  ForwardingController create() => ForwardingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ForwardResult?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ForwardResult?>>(value),
    );
  }
}

String _$forwardingControllerHash() =>
    r'0d06e466f85586d35015ceea4dd510c256a2740d';

abstract class _$ForwardingController
    extends $Notifier<AsyncValue<ForwardResult?>> {
  AsyncValue<ForwardResult?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ForwardResult?>, AsyncValue<ForwardResult?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ForwardResult?>,
                AsyncValue<ForwardResult?>
              >,
              AsyncValue<ForwardResult?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

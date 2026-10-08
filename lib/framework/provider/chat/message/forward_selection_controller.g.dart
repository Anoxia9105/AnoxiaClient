// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forward_selection_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ForwardSelectionController)
final forwardSelectionControllerProvider = ForwardSelectionControllerFamily._();

final class ForwardSelectionControllerProvider
    extends
        $NotifierProvider<ForwardSelectionController, ForwardSelectionState> {
  ForwardSelectionControllerProvider._({
    required ForwardSelectionControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'forwardSelectionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$forwardSelectionControllerHash();

  @override
  String toString() {
    return r'forwardSelectionControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ForwardSelectionController create() => ForwardSelectionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ForwardSelectionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ForwardSelectionState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ForwardSelectionControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$forwardSelectionControllerHash() =>
    r'148f73dee27f0b6b63a595e4763bc2efb5877f66';

final class ForwardSelectionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ForwardSelectionController,
          ForwardSelectionState,
          ForwardSelectionState,
          ForwardSelectionState,
          String
        > {
  ForwardSelectionControllerFamily._()
    : super(
        retry: null,
        name: r'forwardSelectionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ForwardSelectionControllerProvider call(String roomId) =>
      ForwardSelectionControllerProvider._(argument: roomId, from: this);

  @override
  String toString() => r'forwardSelectionControllerProvider';
}

abstract class _$ForwardSelectionController
    extends $Notifier<ForwardSelectionState> {
  late final _$args = ref.$arg as String;
  String get roomId => _$args;

  ForwardSelectionState build(String roomId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ForwardSelectionState, ForwardSelectionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ForwardSelectionState, ForwardSelectionState>,
              ForwardSelectionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(ForwardNavigationTargetController)
final forwardNavigationTargetControllerProvider =
    ForwardNavigationTargetControllerProvider._();

final class ForwardNavigationTargetControllerProvider
    extends
        $NotifierProvider<
          ForwardNavigationTargetController,
          ForwardNavigationTarget?
        > {
  ForwardNavigationTargetControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forwardNavigationTargetControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$forwardNavigationTargetControllerHash();

  @$internal
  @override
  ForwardNavigationTargetController create() =>
      ForwardNavigationTargetController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ForwardNavigationTarget? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ForwardNavigationTarget?>(value),
    );
  }
}

String _$forwardNavigationTargetControllerHash() =>
    r'970a650603eb9d799557d9319c11aee057ed0d83';

abstract class _$ForwardNavigationTargetController
    extends $Notifier<ForwardNavigationTarget?> {
  ForwardNavigationTarget? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<ForwardNavigationTarget?, ForwardNavigationTarget?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ForwardNavigationTarget?, ForwardNavigationTarget?>,
              ForwardNavigationTarget?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

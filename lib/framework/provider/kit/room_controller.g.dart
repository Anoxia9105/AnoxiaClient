// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RoomController)
const roomControllerProvider = RoomControllerFamily._();

final class RoomControllerProvider
    extends $NotifierProvider<RoomController, RoomState> {
  const RoomControllerProvider._({
    required RoomControllerFamily super.from,
    required Room super.argument,
  }) : super(
         retry: null,
         name: r'roomControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roomControllerHash();

  @override
  String toString() {
    return r'roomControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RoomController create() => RoomController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoomState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoomState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RoomControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomControllerHash() => r'085641249eb7cd62c252e5f78c77b07bcf2c9a41';

final class RoomControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          RoomController,
          RoomState,
          RoomState,
          RoomState,
          Room
        > {
  const RoomControllerFamily._()
    : super(
        retry: null,
        name: r'roomControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RoomControllerProvider call(Room room) =>
      RoomControllerProvider._(argument: room, from: this);

  @override
  String toString() => r'roomControllerProvider';
}

abstract class _$RoomController extends $Notifier<RoomState> {
  late final _$args = ref.$arg as Room;
  Room get room => _$args;

  RoomState build(Room room);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<RoomState, RoomState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RoomState, RoomState>,
              RoomState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

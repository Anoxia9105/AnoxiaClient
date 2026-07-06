// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_room_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LiveRoomController)
final liveRoomControllerProvider = LiveRoomControllerFamily._();

final class LiveRoomControllerProvider
    extends $AsyncNotifierProvider<LiveRoomController, RoomState> {
  LiveRoomControllerProvider._({
    required LiveRoomControllerFamily super.from,
    required (String, bool) super.argument,
  }) : super(
         retry: null,
         name: r'liveRoomControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$liveRoomControllerHash();

  @override
  String toString() {
    return r'liveRoomControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  LiveRoomController create() => LiveRoomController();

  @override
  bool operator ==(Object other) {
    return other is LiveRoomControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$liveRoomControllerHash() =>
    r'b7d66eb5bcca23d157e8fb2581b106c742e5df0f';

final class LiveRoomControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LiveRoomController,
          AsyncValue<RoomState>,
          RoomState,
          FutureOr<RoomState>,
          (String, bool)
        > {
  LiveRoomControllerFamily._()
    : super(
        retry: null,
        name: r'liveRoomControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  LiveRoomControllerProvider call(String roomId, bool isHost) =>
      LiveRoomControllerProvider._(argument: (roomId, isHost), from: this);

  @override
  String toString() => r'liveRoomControllerProvider';
}

abstract class _$LiveRoomController extends $AsyncNotifier<RoomState> {
  late final _$args = ref.$arg as (String, bool);
  String get roomId => _$args.$1;
  bool get isHost => _$args.$2;

  FutureOr<RoomState> build(String roomId, bool isHost);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<RoomState>, RoomState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RoomState>, RoomState>,
              AsyncValue<RoomState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

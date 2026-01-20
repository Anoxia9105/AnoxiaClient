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
    extends $AsyncNotifierProvider<RoomController, RoomState> {
  const RoomControllerProvider._({
    required RoomControllerFamily super.from,
    required String super.argument,
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

  @override
  bool operator ==(Object other) {
    return other is RoomControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomControllerHash() => r'8f6bc76473e1c35dd408bd8bcc5dee4c73282377';

final class RoomControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          RoomController,
          AsyncValue<RoomState>,
          RoomState,
          FutureOr<RoomState>,
          String
        > {
  const RoomControllerFamily._()
    : super(
        retry: null,
        name: r'roomControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RoomControllerProvider call(String token) =>
      RoomControllerProvider._(argument: token, from: this);

  @override
  String toString() => r'roomControllerProvider';
}

abstract class _$RoomController extends $AsyncNotifier<RoomState> {
  late final _$args = ref.$arg as String;
  String get token => _$args;

  FutureOr<RoomState> build(String token);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<RoomState>, RoomState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RoomState>, RoomState>,
              AsyncValue<RoomState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(roomToken)
const roomTokenProvider = RoomTokenFamily._();

final class RoomTokenProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  const RoomTokenProvider._({
    required RoomTokenFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'roomTokenProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roomTokenHash();

  @override
  String toString() {
    return r'roomTokenProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return roomToken(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RoomTokenProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomTokenHash() => r'7489ed39fa57044703b07a72755f943ce5627398';

final class RoomTokenFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  const RoomTokenFamily._()
    : super(
        retry: null,
        name: r'roomTokenProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RoomTokenProvider call(String roomId) =>
      RoomTokenProvider._(argument: roomId, from: this);

  @override
  String toString() => r'roomTokenProvider';
}

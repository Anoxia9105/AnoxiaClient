// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_list_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RoomListService)
const roomListServiceProvider = RoomListServiceProvider._();

final class RoomListServiceProvider
    extends $AsyncNotifierProvider<RoomListService, List<ChatRoomVO>> {
  const RoomListServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomListServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomListServiceHash();

  @$internal
  @override
  RoomListService create() => RoomListService();
}

String _$roomListServiceHash() => r'85655fbafed31c7de5e5032d4ee7e93c415e1cf0';

abstract class _$RoomListService extends $AsyncNotifier<List<ChatRoomVO>> {
  FutureOr<List<ChatRoomVO>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<ChatRoomVO>>, List<ChatRoomVO>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ChatRoomVO>>, List<ChatRoomVO>>,
              AsyncValue<List<ChatRoomVO>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ActiveRoomId)
const activeRoomIdProvider = ActiveRoomIdProvider._();

final class ActiveRoomIdProvider
    extends $NotifierProvider<ActiveRoomId, String?> {
  const ActiveRoomIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeRoomIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeRoomIdHash();

  @$internal
  @override
  ActiveRoomId create() => ActiveRoomId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeRoomIdHash() => r'726ee368f00507323304d63dd8ec246dc530a5e5';

abstract class _$ActiveRoomId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(activeRoom)
const activeRoomProvider = ActiveRoomProvider._();

final class ActiveRoomProvider
    extends $FunctionalProvider<ChatRoomVO?, ChatRoomVO?, ChatRoomVO?>
    with $Provider<ChatRoomVO?> {
  const ActiveRoomProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeRoomProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeRoomHash();

  @$internal
  @override
  $ProviderElement<ChatRoomVO?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRoomVO? create(Ref ref) {
    return activeRoom(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRoomVO? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRoomVO?>(value),
    );
  }
}

String _$activeRoomHash() => r'23c67a4e85422a44601478eadf684861ea22c7f0';

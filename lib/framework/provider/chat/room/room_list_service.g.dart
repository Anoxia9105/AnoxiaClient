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

String _$roomListServiceHash() => r'09fae14766f88a4acb5878ed35d44b5eb3c26974';

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

String _$activeRoomIdHash() => r'f019dd813fb76334a3a2246f27cec851c1c3feb3';

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

@ProviderFor(roomEntryTask)
const roomEntryTaskProvider = RoomEntryTaskFamily._();

final class RoomEntryTaskProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  const RoomEntryTaskProvider._({
    required RoomEntryTaskFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'roomEntryTaskProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roomEntryTaskHash();

  @override
  String toString() {
    return r'roomEntryTaskProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return roomEntryTask(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RoomEntryTaskProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roomEntryTaskHash() => r'09ad97b9caff9a0a0b592986b833b18387775a38';

final class RoomEntryTaskFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  const RoomEntryTaskFamily._()
    : super(
        retry: null,
        name: r'roomEntryTaskProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RoomEntryTaskProvider call(String roomId) =>
      RoomEntryTaskProvider._(argument: roomId, from: this);

  @override
  String toString() => r'roomEntryTaskProvider';
}

@ProviderFor(groupRoomList)
const groupRoomListProvider = GroupRoomListProvider._();

final class GroupRoomListProvider
    extends
        $FunctionalProvider<
          List<ChatRoomVO>,
          List<ChatRoomVO>,
          List<ChatRoomVO>
        >
    with $Provider<List<ChatRoomVO>> {
  const GroupRoomListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupRoomListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupRoomListHash();

  @$internal
  @override
  $ProviderElement<List<ChatRoomVO>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<ChatRoomVO> create(Ref ref) {
    return groupRoomList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ChatRoomVO> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ChatRoomVO>>(value),
    );
  }
}

String _$groupRoomListHash() => r'373c92ffd3b679c6e790c49fa982dbb404c91904';

@ProviderFor(RoomSearchQuery)
const roomSearchQueryProvider = RoomSearchQueryProvider._();

final class RoomSearchQueryProvider
    extends $NotifierProvider<RoomSearchQuery, String> {
  const RoomSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomSearchQueryHash();

  @$internal
  @override
  RoomSearchQuery create() => RoomSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$roomSearchQueryHash() => r'71a63adfba4648949d69a3486f1852e4e2acfb36';

abstract class _$RoomSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(filteredRoomList)
const filteredRoomListProvider = FilteredRoomListProvider._();

final class FilteredRoomListProvider
    extends
        $FunctionalProvider<
          List<ChatRoomVO>,
          List<ChatRoomVO>,
          List<ChatRoomVO>
        >
    with $Provider<List<ChatRoomVO>> {
  const FilteredRoomListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredRoomListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredRoomListHash();

  @$internal
  @override
  $ProviderElement<List<ChatRoomVO>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<ChatRoomVO> create(Ref ref) {
    return filteredRoomList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ChatRoomVO> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ChatRoomVO>>(value),
    );
  }
}

String _$filteredRoomListHash() => r'631b1bd63b8bd90c6ea639950a9d46da8f09b624';

@ProviderFor(totalUnreadCount)
const totalUnreadCountProvider = TotalUnreadCountProvider._();

final class TotalUnreadCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  const TotalUnreadCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalUnreadCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalUnreadCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return totalUnreadCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$totalUnreadCountHash() => r'eeb1e180ff6a80acbb6d12b8cdd2fc16ed988099';

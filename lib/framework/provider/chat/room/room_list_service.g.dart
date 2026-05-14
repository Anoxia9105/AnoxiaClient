// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_list_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 聊天室列表服务
///
/// 负责管理聊天室列表的获取、刷新、排序和本地状态维护。
/// 采用 keepAlive 模式，确保列表数据全局共享。

@ProviderFor(RoomListService)
const roomListServiceProvider = RoomListServiceProvider._();

/// 聊天室列表服务
///
/// 负责管理聊天室列表的获取、刷新、排序和本地状态维护。
/// 采用 keepAlive 模式，确保列表数据全局共享。
final class RoomListServiceProvider
    extends $AsyncNotifierProvider<RoomListService, List<ChatRoomVO>> {
  /// 聊天室列表服务
  ///
  /// 负责管理聊天室列表的获取、刷新、排序和本地状态维护。
  /// 采用 keepAlive 模式，确保列表数据全局共享。
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

String _$roomListServiceHash() => r'c5769ccc67a10c54a23dcea5886d2e600e1939b9';

/// 聊天室列表服务
///
/// 负责管理聊天室列表的获取、刷新、排序和本地状态维护。
/// 采用 keepAlive 模式，确保列表数据全局共享。

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

/// 当前选中的聊天室 ID

@ProviderFor(ActiveRoomId)
const activeRoomIdProvider = ActiveRoomIdProvider._();

/// 当前选中的聊天室 ID
final class ActiveRoomIdProvider
    extends $NotifierProvider<ActiveRoomId, String?> {
  /// 当前选中的聊天室 ID
  const ActiveRoomIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeRoomIdProvider',
        isAutoDispose: false,
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

String _$activeRoomIdHash() => r'43d29da720d77afeb50534e806ca9ef3559e690b';

/// 当前选中的聊天室 ID

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

/// 当前选中的聊天室对象

@ProviderFor(activeRoom)
const activeRoomProvider = ActiveRoomProvider._();

/// 当前选中的聊天室对象

final class ActiveRoomProvider
    extends $FunctionalProvider<ChatRoomVO?, ChatRoomVO?, ChatRoomVO?>
    with $Provider<ChatRoomVO?> {
  /// 当前选中的聊天室对象
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

String _$activeRoomHash() => r'0a582900eac84bf2f437acd5bed3bcc0a1a9118f';

/// 进入房间时的初始化任务
///
/// 确保消息和成员数据已同步到本地

@ProviderFor(roomEntryTask)
const roomEntryTaskProvider = RoomEntryTaskFamily._();

/// 进入房间时的初始化任务
///
/// 确保消息和成员数据已同步到本地

final class RoomEntryTaskProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// 进入房间时的初始化任务
  ///
  /// 确保消息和成员数据已同步到本地
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

/// 进入房间时的初始化任务
///
/// 确保消息和成员数据已同步到本地

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

  /// 进入房间时的初始化任务
  ///
  /// 确保消息和成员数据已同步到本地

  RoomEntryTaskProvider call(String roomId) =>
      RoomEntryTaskProvider._(argument: roomId, from: this);

  @override
  String toString() => r'roomEntryTaskProvider';
}

/// 群聊房间列表（房间类型为 GROUP）

@ProviderFor(groupRoomList)
const groupRoomListProvider = GroupRoomListProvider._();

/// 群聊房间列表（房间类型为 GROUP）

final class GroupRoomListProvider
    extends
        $FunctionalProvider<
          List<ChatRoomVO>,
          List<ChatRoomVO>,
          List<ChatRoomVO>
        >
    with $Provider<List<ChatRoomVO>> {
  /// 群聊房间列表（房间类型为 GROUP）
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

/// 房间搜索关键词

@ProviderFor(RoomSearchQuery)
const roomSearchQueryProvider = RoomSearchQueryProvider._();

/// 房间搜索关键词
final class RoomSearchQueryProvider
    extends $NotifierProvider<RoomSearchQuery, String> {
  /// 房间搜索关键词
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

/// 房间搜索关键词

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

/// 根据关键词过滤后的聊天室列表
///
/// 匹配规则：房间名称 或 最后一条消息内容

@ProviderFor(filteredRoomList)
const filteredRoomListProvider = FilteredRoomListProvider._();

/// 根据关键词过滤后的聊天室列表
///
/// 匹配规则：房间名称 或 最后一条消息内容

final class FilteredRoomListProvider
    extends
        $FunctionalProvider<
          List<ChatRoomVO>,
          List<ChatRoomVO>,
          List<ChatRoomVO>
        >
    with $Provider<List<ChatRoomVO>> {
  /// 根据关键词过滤后的聊天室列表
  ///
  /// 匹配规则：房间名称 或 最后一条消息内容
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

/// 总未读消息数
///
/// 排除当前正在查看的房间

@ProviderFor(totalUnreadCount)
const totalUnreadCountProvider = TotalUnreadCountProvider._();

/// 总未读消息数
///
/// 排除当前正在查看的房间

final class TotalUnreadCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 总未读消息数
  ///
  /// 排除当前正在查看的房间
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

String _$totalUnreadCountHash() => r'28ba55bb5ba482ddd0f850e95fd5ebcd14e7bae5';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_list_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RoomListRefreshFailed)
final roomListRefreshFailedProvider = RoomListRefreshFailedProvider._();

final class RoomListRefreshFailedProvider
    extends $NotifierProvider<RoomListRefreshFailed, bool> {
  RoomListRefreshFailedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomListRefreshFailedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomListRefreshFailedHash();

  @$internal
  @override
  RoomListRefreshFailed create() => RoomListRefreshFailed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$roomListRefreshFailedHash() =>
    r'7cc821e29f3171ca61a4fcc47664648e8fe37afc';

abstract class _$RoomListRefreshFailed extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 聊天室列表服务
///
/// 负责管理聊天室列表的获取、刷新、排序和本地状态维护。
/// 采用 keepAlive 模式，确保列表数据全局共享。

@ProviderFor(RoomListService)
final roomListServiceProvider = RoomListServiceProvider._();

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
  RoomListServiceProvider._()
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

String _$roomListServiceHash() => r'9bd7ca81ec98b23126afa5b0ca4da4e189171c41';

/// 聊天室列表服务
///
/// 负责管理聊天室列表的获取、刷新、排序和本地状态维护。
/// 采用 keepAlive 模式，确保列表数据全局共享。

abstract class _$RoomListService extends $AsyncNotifier<List<ChatRoomVO>> {
  FutureOr<List<ChatRoomVO>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}

/// 当前选中的聊天室 ID 全局指针

@ProviderFor(ActiveRoomId)
final activeRoomIdProvider = ActiveRoomIdProvider._();

/// 当前选中的聊天室 ID 全局指针
final class ActiveRoomIdProvider
    extends $NotifierProvider<ActiveRoomId, String?> {
  /// 当前选中的聊天室 ID 全局指针
  ActiveRoomIdProvider._()
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

String _$activeRoomIdHash() => r'415f2b8b3d222f0c8bc78a9612e586e5887955a6';

/// 当前选中的聊天室 ID 全局指针

abstract class _$ActiveRoomId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 当前登录会话内完成过首次同步的房间，包含确实没有消息的房间。

@ProviderFor(RoomInitialLoads)
final roomInitialLoadsProvider = RoomInitialLoadsProvider._();

/// 当前登录会话内完成过首次同步的房间，包含确实没有消息的房间。
final class RoomInitialLoadsProvider
    extends $NotifierProvider<RoomInitialLoads, Set<String>> {
  /// 当前登录会话内完成过首次同步的房间，包含确实没有消息的房间。
  RoomInitialLoadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomInitialLoadsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomInitialLoadsHash();

  @$internal
  @override
  RoomInitialLoads create() => RoomInitialLoads();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$roomInitialLoadsHash() => r'02ae031615424edf2eea6cb29be40b9621389cb6';

/// 当前登录会话内完成过首次同步的房间，包含确实没有消息的房间。

abstract class _$RoomInitialLoads extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 进入房间时的初始化任务
///
/// 确保消息和成员数据已同步到本地

@ProviderFor(roomEntryTask)
final roomEntryTaskProvider = RoomEntryTaskFamily._();

/// 进入房间时的初始化任务
///
/// 确保消息和成员数据已同步到本地

final class RoomEntryTaskProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// 进入房间时的初始化任务
  ///
  /// 确保消息和成员数据已同步到本地
  RoomEntryTaskProvider._({
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

String _$roomEntryTaskHash() => r'8c0f3e10a365ed23b2e300f5eb307c2d7cc456de';

/// 进入房间时的初始化任务
///
/// 确保消息和成员数据已同步到本地

final class RoomEntryTaskFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  RoomEntryTaskFamily._()
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

/// 保留选中的房间，但后台不视为正在阅读。

@ProviderFor(activelyViewedRoomId)
final activelyViewedRoomIdProvider = ActivelyViewedRoomIdProvider._();

/// 保留选中的房间，但后台不视为正在阅读。

final class ActivelyViewedRoomIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// 保留选中的房间，但后台不视为正在阅读。
  ActivelyViewedRoomIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activelyViewedRoomIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activelyViewedRoomIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return activelyViewedRoomId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activelyViewedRoomIdHash() =>
    r'c8e4c8d5ec0a3ac542d6423ec126a13c4cfd0c60';

/// 群聊房间列表（房间类型为 GROUP）

@ProviderFor(groupRoomList)
final groupRoomListProvider = GroupRoomListProvider._();

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
  GroupRoomListProvider._()
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
final roomSearchQueryProvider = RoomSearchQueryProvider._();

/// 房间搜索关键词
final class RoomSearchQueryProvider
    extends $NotifierProvider<RoomSearchQuery, String> {
  /// 房间搜索关键词
  RoomSearchQueryProvider._()
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

String _$roomSearchQueryHash() => r'a0073b39876b6da2dab28a5a8adbe90398e6116e';

/// 房间搜索关键词

abstract class _$RoomSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 根据关键词过滤后的聊天室列表
///
/// 匹配规则：房间名称 或 最后一条消息内容
///
/// 防御约束：查询型 Provider 返回空集合而非抛错/空引用。

@ProviderFor(filteredRoomList)
final filteredRoomListProvider = FilteredRoomListProvider._();

/// 根据关键词过滤后的聊天室列表
///
/// 匹配规则：房间名称 或 最后一条消息内容
///
/// 防御约束：查询型 Provider 返回空集合而非抛错/空引用。

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
  ///
  /// 防御约束：查询型 Provider 返回空集合而非抛错/空引用。
  FilteredRoomListProvider._()
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

String _$filteredRoomListHash() => r'd453141813eb632dbee0545b42fb9ddd93ae1949';

/// 总未读消息数
///
/// 排除当前正在查看的房间

@ProviderFor(totalUnreadCount)
final totalUnreadCountProvider = TotalUnreadCountProvider._();

/// 总未读消息数
///
/// 排除当前正在查看的房间

final class TotalUnreadCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 总未读消息数
  ///
  /// 排除当前正在查看的房间
  TotalUnreadCountProvider._()
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

/// 根据房间 ID 获取对应的聊天室对象

@ProviderFor(currentRoom)
final currentRoomProvider = CurrentRoomFamily._();

/// 根据房间 ID 获取对应的聊天室对象

final class CurrentRoomProvider
    extends $FunctionalProvider<ChatRoomVO?, ChatRoomVO?, ChatRoomVO?>
    with $Provider<ChatRoomVO?> {
  /// 根据房间 ID 获取对应的聊天室对象
  CurrentRoomProvider._({
    required CurrentRoomFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'currentRoomProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currentRoomHash();

  @override
  String toString() {
    return r'currentRoomProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ChatRoomVO?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRoomVO? create(Ref ref) {
    final argument = this.argument as String;
    return currentRoom(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRoomVO? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRoomVO?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentRoomProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentRoomHash() => r'0a08f62d9c4bed84d2f73af25b7eb3737e2093c0';

/// 根据房间 ID 获取对应的聊天室对象

final class CurrentRoomFamily extends $Family
    with $FunctionalFamilyOverride<ChatRoomVO?, String> {
  CurrentRoomFamily._()
    : super(
        retry: null,
        name: r'currentRoomProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 根据房间 ID 获取对应的聊天室对象

  CurrentRoomProvider call(String roomId) =>
      CurrentRoomProvider._(argument: roomId, from: this);

  @override
  String toString() => r'currentRoomProvider';
}

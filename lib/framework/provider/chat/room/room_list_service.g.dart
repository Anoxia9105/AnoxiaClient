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

String _$roomListServiceHash() => r'c8fc66f1c11232f7c4f0c44338bde4cd946c2a6c';

/// 聊天室列表服务
///
/// 负责管理聊天室列表的获取、刷新、排序和本地状态维护。
/// 采用 keepAlive 模式，确保列表数据全局共享。

abstract class _$RoomListService extends $AsyncNotifier<List<ChatRoomVO>> {
  FutureOr<List<ChatRoomVO>> build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
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

String _$activeRoomIdHash() => r'43d29da720d77afeb50534e806ca9ef3559e690b';

/// 当前选中的聊天室 ID 全局指针

abstract class _$ActiveRoomId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
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

String _$roomEntryTaskHash() => r'78570d9ba90ca5661d88ed4e6efe4c792b144e99';

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
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 根据关键词过滤后的聊天室列表
///
/// 匹配规则：房间名称 或 最后一条消息内容

@ProviderFor(filteredRoomList)
final filteredRoomListProvider = FilteredRoomListProvider._();

/// 根据关键词过滤后的聊天室列表
///
/// 匹配规则：房间名称 或 最后一条消息内容

final class FilteredRoomListProvider
    extends
        $FunctionalProvider<
          List<ChatRoomVO>?,
          List<ChatRoomVO>?,
          List<ChatRoomVO>?
        >
    with $Provider<List<ChatRoomVO>?> {
  /// 根据关键词过滤后的聊天室列表
  ///
  /// 匹配规则：房间名称 或 最后一条消息内容
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
  $ProviderElement<List<ChatRoomVO>?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ChatRoomVO>? create(Ref ref) {
    return filteredRoomList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ChatRoomVO>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ChatRoomVO>?>(value),
    );
  }
}

String _$filteredRoomListHash() => r'e0a01ef62419852d8a332f7f0255ce6275095820';

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

String _$currentRoomHash() => r'5dc9342c5808fab97af18ca98c631a3c9bc6a548';

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

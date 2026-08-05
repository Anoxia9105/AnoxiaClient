// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_join_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 入群申请列表服务（按房间缓存）
///
/// 供「入群申请」入口的红点徽标实时展示待处理申请数，
/// 由 WebSocket 事件与审批操作触发刷新。

@ProviderFor(GroupJoinRequestsService)
final groupJoinRequestsServiceProvider = GroupJoinRequestsServiceFamily._();

/// 入群申请列表服务（按房间缓存）
///
/// 供「入群申请」入口的红点徽标实时展示待处理申请数，
/// 由 WebSocket 事件与审批操作触发刷新。
final class GroupJoinRequestsServiceProvider
    extends
        $AsyncNotifierProvider<
          GroupJoinRequestsService,
          List<Map<String, dynamic>>
        > {
  /// 入群申请列表服务（按房间缓存）
  ///
  /// 供「入群申请」入口的红点徽标实时展示待处理申请数，
  /// 由 WebSocket 事件与审批操作触发刷新。
  GroupJoinRequestsServiceProvider._({
    required GroupJoinRequestsServiceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'groupJoinRequestsServiceProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupJoinRequestsServiceHash();

  @override
  String toString() {
    return r'groupJoinRequestsServiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  GroupJoinRequestsService create() => GroupJoinRequestsService();

  @override
  bool operator ==(Object other) {
    return other is GroupJoinRequestsServiceProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupJoinRequestsServiceHash() =>
    r'd1ee4ce754000decb2c20eda83916fdbb8f1262f';

/// 入群申请列表服务（按房间缓存）
///
/// 供「入群申请」入口的红点徽标实时展示待处理申请数，
/// 由 WebSocket 事件与审批操作触发刷新。

final class GroupJoinRequestsServiceFamily extends $Family
    with
        $ClassFamilyOverride<
          GroupJoinRequestsService,
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>,
          String
        > {
  GroupJoinRequestsServiceFamily._()
    : super(
        retry: null,
        name: r'groupJoinRequestsServiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// 入群申请列表服务（按房间缓存）
  ///
  /// 供「入群申请」入口的红点徽标实时展示待处理申请数，
  /// 由 WebSocket 事件与审批操作触发刷新。

  GroupJoinRequestsServiceProvider call(String roomId) =>
      GroupJoinRequestsServiceProvider._(argument: roomId, from: this);

  @override
  String toString() => r'groupJoinRequestsServiceProvider';
}

/// 入群申请列表服务（按房间缓存）
///
/// 供「入群申请」入口的红点徽标实时展示待处理申请数，
/// 由 WebSocket 事件与审批操作触发刷新。

abstract class _$GroupJoinRequestsService
    extends $AsyncNotifier<List<Map<String, dynamic>>> {
  late final _$args = ref.$arg as String;
  String get roomId => _$args;

  FutureOr<List<Map<String, dynamic>>> build(String roomId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<Map<String, dynamic>>>,
              List<Map<String, dynamic>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<Map<String, dynamic>>>,
                List<Map<String, dynamic>>
              >,
              AsyncValue<List<Map<String, dynamic>>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 待处理入群申请数量（红点提示用）
///
/// 仅统计状态为 0（待处理）的申请数

@ProviderFor(pendingGroupJoinRequestCount)
final pendingGroupJoinRequestCountProvider =
    PendingGroupJoinRequestCountFamily._();

/// 待处理入群申请数量（红点提示用）
///
/// 仅统计状态为 0（待处理）的申请数

final class PendingGroupJoinRequestCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// 待处理入群申请数量（红点提示用）
  ///
  /// 仅统计状态为 0（待处理）的申请数
  PendingGroupJoinRequestCountProvider._({
    required PendingGroupJoinRequestCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pendingGroupJoinRequestCountProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingGroupJoinRequestCountHash();

  @override
  String toString() {
    return r'pendingGroupJoinRequestCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return pendingGroupJoinRequestCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingGroupJoinRequestCountProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingGroupJoinRequestCountHash() =>
    r'85a4be2af76f888bff63da02fb4f8d367aa90f2d';

/// 待处理入群申请数量（红点提示用）
///
/// 仅统计状态为 0（待处理）的申请数

final class PendingGroupJoinRequestCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  PendingGroupJoinRequestCountFamily._()
    : super(
        retry: null,
        name: r'pendingGroupJoinRequestCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// 待处理入群申请数量（红点提示用）
  ///
  /// 仅统计状态为 0（待处理）的申请数

  PendingGroupJoinRequestCountProvider call(String roomId) =>
      PendingGroupJoinRequestCountProvider._(argument: roomId, from: this);

  @override
  String toString() => r'pendingGroupJoinRequestCountProvider';
}

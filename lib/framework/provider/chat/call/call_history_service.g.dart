// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_history_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 通话记录页面状态管理（按房间过滤）
///
/// - 通话记录并入会话详情后不再常驻主框架页签，
///   provider 按房间 family（autoDispose：弹窗/页面关闭即释放）；
/// - build 即触发首屏加载（服务端按 [roomId] 过滤后分页聚合）；
/// - [refresh] 重置回第一页并替换旧数据；
/// - [loadMore] 聚合条目按页映射 messageId 去重后追加；
/// - 排序切换经 [setOrderBy]，切换后由 [refresh] 完整重拉。

@ProviderFor(CallHistoryList)
final callHistoryListProvider = CallHistoryListFamily._();

/// 通话记录页面状态管理（按房间过滤）
///
/// - 通话记录并入会话详情后不再常驻主框架页签，
///   provider 按房间 family（autoDispose：弹窗/页面关闭即释放）；
/// - build 即触发首屏加载（服务端按 [roomId] 过滤后分页聚合）；
/// - [refresh] 重置回第一页并替换旧数据；
/// - [loadMore] 聚合条目按页映射 messageId 去重后追加；
/// - 排序切换经 [setOrderBy]，切换后由 [refresh] 完整重拉。
final class CallHistoryListProvider
    extends $NotifierProvider<CallHistoryList, CallHistoryState> {
  /// 通话记录页面状态管理（按房间过滤）
  ///
  /// - 通话记录并入会话详情后不再常驻主框架页签，
  ///   provider 按房间 family（autoDispose：弹窗/页面关闭即释放）；
  /// - build 即触发首屏加载（服务端按 [roomId] 过滤后分页聚合）；
  /// - [refresh] 重置回第一页并替换旧数据；
  /// - [loadMore] 聚合条目按页映射 messageId 去重后追加；
  /// - 排序切换经 [setOrderBy]，切换后由 [refresh] 完整重拉。
  CallHistoryListProvider._({
    required CallHistoryListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'callHistoryListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$callHistoryListHash();

  @override
  String toString() {
    return r'callHistoryListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CallHistoryList create() => CallHistoryList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CallHistoryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CallHistoryState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CallHistoryListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$callHistoryListHash() => r'de5be5e4db82c2b3ef661791f24468f2faa35266';

/// 通话记录页面状态管理（按房间过滤）
///
/// - 通话记录并入会话详情后不再常驻主框架页签，
///   provider 按房间 family（autoDispose：弹窗/页面关闭即释放）；
/// - build 即触发首屏加载（服务端按 [roomId] 过滤后分页聚合）；
/// - [refresh] 重置回第一页并替换旧数据；
/// - [loadMore] 聚合条目按页映射 messageId 去重后追加；
/// - 排序切换经 [setOrderBy]，切换后由 [refresh] 完整重拉。

final class CallHistoryListFamily extends $Family
    with
        $ClassFamilyOverride<
          CallHistoryList,
          CallHistoryState,
          CallHistoryState,
          CallHistoryState,
          String
        > {
  CallHistoryListFamily._()
    : super(
        retry: null,
        name: r'callHistoryListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 通话记录页面状态管理（按房间过滤）
  ///
  /// - 通话记录并入会话详情后不再常驻主框架页签，
  ///   provider 按房间 family（autoDispose：弹窗/页面关闭即释放）；
  /// - build 即触发首屏加载（服务端按 [roomId] 过滤后分页聚合）；
  /// - [refresh] 重置回第一页并替换旧数据；
  /// - [loadMore] 聚合条目按页映射 messageId 去重后追加；
  /// - 排序切换经 [setOrderBy]，切换后由 [refresh] 完整重拉。

  CallHistoryListProvider call(String roomId) =>
      CallHistoryListProvider._(argument: roomId, from: this);

  @override
  String toString() => r'callHistoryListProvider';
}

/// 通话记录页面状态管理（按房间过滤）
///
/// - 通话记录并入会话详情后不再常驻主框架页签，
///   provider 按房间 family（autoDispose：弹窗/页面关闭即释放）；
/// - build 即触发首屏加载（服务端按 [roomId] 过滤后分页聚合）；
/// - [refresh] 重置回第一页并替换旧数据；
/// - [loadMore] 聚合条目按页映射 messageId 去重后追加；
/// - 排序切换经 [setOrderBy]，切换后由 [refresh] 完整重拉。

abstract class _$CallHistoryList extends $Notifier<CallHistoryState> {
  late final _$args = ref.$arg as String;
  String get roomId => _$args;

  CallHistoryState build(String roomId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CallHistoryState, CallHistoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CallHistoryState, CallHistoryState>,
              CallHistoryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

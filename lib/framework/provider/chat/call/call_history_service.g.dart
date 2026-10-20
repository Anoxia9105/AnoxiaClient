// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_history_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 通话记录页面状态管理
///
/// - build 即触发首屏加载（IndexedStack 常驻预构建，进首页拉一次）
/// - [refresh] 重置回第一页并替换旧数据
/// - [loadMore] 聚合条目按页映射 messageId 去重后追加
/// - 排序切换经 [setOrderBy]，切换后由 [refresh] 完整重拉

@ProviderFor(CallHistoryList)
final callHistoryListProvider = CallHistoryListProvider._();

/// 通话记录页面状态管理
///
/// - build 即触发首屏加载（IndexedStack 常驻预构建，进首页拉一次）
/// - [refresh] 重置回第一页并替换旧数据
/// - [loadMore] 聚合条目按页映射 messageId 去重后追加
/// - 排序切换经 [setOrderBy]，切换后由 [refresh] 完整重拉
final class CallHistoryListProvider
    extends $NotifierProvider<CallHistoryList, CallHistoryState> {
  /// 通话记录页面状态管理
  ///
  /// - build 即触发首屏加载（IndexedStack 常驻预构建，进首页拉一次）
  /// - [refresh] 重置回第一页并替换旧数据
  /// - [loadMore] 聚合条目按页映射 messageId 去重后追加
  /// - 排序切换经 [setOrderBy]，切换后由 [refresh] 完整重拉
  CallHistoryListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callHistoryListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callHistoryListHash();

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
}

String _$callHistoryListHash() => r'6a3af2140a4adabde759939801efec79b90e61ad';

/// 通话记录页面状态管理
///
/// - build 即触发首屏加载（IndexedStack 常驻预构建，进首页拉一次）
/// - [refresh] 重置回第一页并替换旧数据
/// - [loadMore] 聚合条目按页映射 messageId 去重后追加
/// - 排序切换经 [setOrderBy]，切换后由 [refresh] 完整重拉

abstract class _$CallHistoryList extends $Notifier<CallHistoryState> {
  CallHistoryState build();
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
    return element.handleCreate(ref, build);
  }
}

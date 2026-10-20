import 'package:anoxia/domain/repositories/call_repository.dart';
import 'package:anoxia/framework/domain/call_log_entry.dart';
import 'package:anoxia/framework/provider/core/call_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'call_history_service.g.dart';

/// 通话记录状态
///
/// 查询路径尽量不抛异常：错误以 [error] 承载，列表保持上一页数据，
/// 页面据此决定显示重试还是静默保留。
class CallHistoryState {
  /// 当前已聚合条目（顺序与 [CallHistoryState.orderBy] 一致）
  final List<CallLogEntry> entries;

  /// 服务端全量会话数，用于 hasMore 判断
  final int total;

  /// 排序方向（将作为下一次请求 query 传入）
  final String orderBy;

  /// 首屏加载中
  final bool initialLoading;

  /// 追加下一页中
  final bool loadingMore;

  /// 首屏加载失败（仅首屏失败时置位）
  final Object? error;

  const CallHistoryState({
    this.entries = const [],
    this.total = 0,
    this.orderBy = 'desc',
    this.initialLoading = false,
    this.loadingMore = false,
    this.error,
  });

  bool get hasMore => entries.length < total && !loadingMore;

  CallHistoryState copyWith({
    List<CallLogEntry>? entries,
    int? total,
    String? orderBy,
    bool? initialLoading,
    bool? loadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return CallHistoryState(
      entries: entries ?? this.entries,
      total: total ?? this.total,
      orderBy: orderBy ?? this.orderBy,
      initialLoading: initialLoading ?? this.initialLoading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 通话记录页面状态管理
///
/// - build 即触发首屏加载（IndexedStack 常驻预构建，进首页拉一次）
/// - [refresh] 重置回第一页并替换旧数据
/// - [loadMore] 聚合条目按页映射 messageId 去重后追加
/// - 排序切换经 [setOrderBy]，切换后由 [refresh] 完整重拉
@Riverpod(keepAlive: true)
class CallHistoryList extends _$CallHistoryList {
  /// 单页条数（与服务端 clamp 范围一致）
  static const int _pageSize = 20;

  /// 下一次 loadMore 的页码（服务端以起始行查询计页）
  int _nextPage = 1;

  /// 排序阶段标记：加载完成前丢弃过期响应
  int _generation = 0;

  @override
  CallHistoryState build() {
    // build 内不可同步读 state：refresh 交给事件循环延迟执行
    Future<void>(() => refresh());
    return const CallHistoryState(initialLoading: true);
  }

  CallRepository get _repo => ref.read(callRepositoryProvider);

  /// 重置到第一页
  Future<void> refresh() async {
    final generation = ++_generation;
    final orderBy = state.orderBy;
    try {
      final page = await _repo.fetchCallHistory(
        pageNum: 1,
        pageSize: _pageSize,
        orderBy: orderBy,
      );
      if (generation != _generation) return;
      _nextPage = 2;
      state = state.copyWith(
        entries: page.entries,
        total: page.total,
        initialLoading: false,
        loadingMore: false,
        clearError: true,
      );
    } catch (e) {
      if (generation != _generation) return;
      state = state.copyWith(
        entries: const [],
        total: 0,
        initialLoading: false,
        loadingMore: false,
        error: e,
      );
    }
  }

  /// 追加下一页；失败静默（保留当前页，下次滚动/下拉可重试）
  Future<void> loadMore() async {
    final current = state;
    if (current.loadingMore || !current.hasMore) return;
    final generation = _generation;
    state = current.copyWith(loadingMore: true);
    try {
      final page = await _repo.fetchCallHistory(
        pageNum: _nextPage < 1 ? 1 : _nextPage,
        pageSize: _pageSize,
        orderBy: current.orderBy,
      );
      if (generation != _generation) return;
      _nextPage = _nextPage + 1;
      state = state.copyWith(
        entries: dropDuplicateEntries([...current.entries, ...page.entries]),
        total: page.total,
        loadingMore: false,
      );
    } catch (e) {
      if (generation != _generation) return;
      state = state.copyWith(loadingMore: false);
    }
  }

  /// 切换排序方向并重拉
  Future<void> setOrderBy(String orderBy) async {
    if (orderBy == state.orderBy) return;
    state = state.copyWith(orderBy: orderBy, initialLoading: true);
    await refresh();
  }
}

/// 追加页与既有页按 messageId 去重（服务端数据落盘后 ID 全局唯一）
List<CallLogEntry> dropDuplicateEntries(List<CallLogEntry> entries) {
  final seen = <String>{};
  final result = <CallLogEntry>[];
  for (final entry in entries) {
    if (seen.add(entry.messageId)) result.add(entry);
  }
  return result;
}

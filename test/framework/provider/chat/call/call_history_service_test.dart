import 'dart:async';

import 'package:anoxia/domain/repositories/call_repository.dart';
import 'package:anoxia/framework/domain/call_log_entry.dart';
import 'package:anoxia/framework/domain/room_call_status.dart';
import 'package:anoxia/framework/provider/chat/call/call_history_service.dart';
import 'package:anoxia/framework/provider/core/call_repository_provider.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 可注入响应序列的假通话仓库。
///
/// - [requests] 记录每次请求参数（页码/排序）
/// - [queue] 按序消费响应：[CallHistoryPageData] 成功、[Object] 为失败、
///   [Completer] 手动放行（用于竞态测试）
class _StubCallRepository implements CallRepository {
  final requests = <({int pageNum, int pageSize, String orderBy})>[];
  final queue = <Object>[];

  void enqueueSuccessful(CallHistoryPageData page) => queue.add(page);

  void enqueueFailure(Object error) => queue.add(error);

  void enqueuePending(Completer<CallHistoryPageData> completer) =>
      queue.add(completer);

  @override
  Future<CallHistoryPageData> fetchCallHistory({
    required int pageNum,
    required int pageSize,
    required String orderBy,
  }) {
    requests.add((pageNum: pageNum, pageSize: pageSize, orderBy: orderBy));
    final next = queue.isEmpty ? Object() : queue.removeAt(0);
    if (next is Completer<CallHistoryPageData>) return next.future;
    if (next is CallHistoryPageData) return Future.value(next);
    return Future.error(next is Exception ? next : StateError('响应未入队'));
  }

  @override
  Future<RoomCallStatus> fetchCallStatus(String roomId) =>
      throw UnimplementedError();

  @override
  Future<String> fetchCallToken(String roomId) => throw UnimplementedError();

  @override
  Future<bool> removeParticipant(String roomId, String identity) =>
      throw UnimplementedError();
}

CallLogEntry entry(String messageId, {String roomId = 'room-a'}) {
  return CallLogEntry(
    messageId: messageId,
    roomId: roomId,
    roomType: 0,
    outgoing: true,
    startAt: 1000,
    status: CallLogStatus.completed,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _StubCallRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _StubCallRepository();
    container = ProviderContainer(
      overrides: [callRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  CallHistoryState currentState() => container.read(callHistoryListProvider);

  Future<void> settle() => pumpEventQueue();

  void boot() => container.read(callHistoryListProvider.notifier);

  test('进页面触发首屏加载并填充条目与全量数', () async {
    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m1', roomId: 'a')], total: 5),
    );
    boot();
    await settle();

    final s = currentState();
    expect(s.entries.map((e) => e.messageId), ['m1']);
    expect(s.total, 5);
    expect(s.initialLoading, isFalse);
    expect(s.hasMore, isTrue);
    expect(s.error, isNull);
    expect(repository.requests.single.orderBy, 'desc');
    expect(repository.requests.single.pageNum, 1);
  });

  test('空会话列表没有错误也没有更多页', () async {
    repository.enqueueSuccessful(CallHistoryPageData.empty);
    boot();
    await settle();

    final s = currentState();
    expect(s.entries, isEmpty);
    expect(s.total, 0);
    expect(s.hasMore, isFalse);
    expect(s.error, isNull);
  });

  test('首屏失败时错误落位到 state，不抛出', () async {
    repository.enqueueFailure(const FormatException('bad response'));
    boot();
    await settle();

    final s = currentState();
    expect(s.entries, isEmpty);
    expect(s.error, isA<FormatException>());
    expect(s.initialLoading, isFalse);
  });

  test('loadMore 按页追加且按 messageId 去重', () async {
    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m1'), entry('m2')], total: 3),
    );
    boot();
    await settle();

    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m2'), entry('m3')], total: 3),
    );
    await container.read(callHistoryListProvider.notifier).loadMore();
    await settle();

    final s = currentState();
    expect(s.entries.map((e) => e.messageId), ['m1', 'm2', 'm3']);
    expect(s.hasMore, isFalse);
    expect(s.loadingMore, isFalse);
    expect(repository.requests.map((r) => r.pageNum), [1, 2]);
  });

  test('追加页失败时保留既有条目且仍可重试', () async {
    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m1')], total: 2),
    );
    boot();
    await settle();

    repository.enqueueFailure(StateError('network down'));
    await container.read(callHistoryListProvider.notifier).loadMore();
    await settle();

    final s = currentState();
    expect(s.entries.map((e) => e.messageId), ['m1']);
    expect(s.loadingMore, isFalse);
    expect(s.hasMore, isTrue);
    expect(s.error, isNull);
  });

  test('切换排序方向会重置列表并按新方向重拉', () async {
    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m1')], total: 1),
    );
    boot();
    await settle();

    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m9')], total: 1),
    );
    await container.read(callHistoryListProvider.notifier).setOrderBy('asc');
    await settle();

    final s = currentState();
    expect(s.entries.map((e) => e.messageId), ['m9']);
    expect(s.orderBy, 'asc');
    expect(repository.requests.map((r) => r.orderBy), ['desc', 'asc']);
    expect(repository.requests.last.pageNum, 1);
  });

  test('加载期间发生的 refresh 会丢弃过期的追加页', () async {
    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m1')], total: 2),
    );
    boot();
    await settle();

    final pending = Completer<CallHistoryPageData>();
    repository.enqueuePending(pending);
    final loadMoreFuture =
        container.read(callHistoryListProvider.notifier).loadMore();

    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m1')], total: 1),
    );
    final refreshFuture =
        container.read(callHistoryListProvider.notifier).refresh();

    // 追加页完成后才被丢弃：refresh 的 generation 更新使其过期
    pending.complete(
      CallHistoryPageData(entries: [entry('m1')], total: 1),
    );
    await Future.wait([loadMoreFuture, refreshFuture]);

    final s = currentState();
    expect(s.entries.map((e) => e.messageId), ['m1']);
    expect(s.total, 1);
    expect(s.loadingMore, isFalse);
    expect(repository.requests.map((r) => r.pageNum), [1, 2, 1]);
  });

  test('通话记录挂载在主框架侧栏第二项', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final items = container.read(layoutControllerProvider).items;
    expect(items[2].name, 'sidebar_calls');
    expect(items.last.name, 'sidebar_setting');
  });
}

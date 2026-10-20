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
/// - [requests] 记录每次请求参数（页码/排序/房间过滤）
/// - [queue] 按序消费响应：[CallHistoryPageData] 成功、[Object] 为失败、
///   [Completer] 手动放行（用于竞态测试）
class _StubCallRepository implements CallRepository {
  final requests =
      <({int pageNum, int pageSize, String orderBy, String? roomId})>[];
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
    String? roomId,
  }) {
    requests.add(
      (
        pageNum: pageNum,
        pageSize: pageSize,
        orderBy: orderBy,
        roomId: roomId,
      ),
    );
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

  /// autoDispose family：没有常驻 listener 时 read 后下一个事件循环就会被
  /// 销毁，build 里延迟执行的 refresh 会因 Ref 失效抛错。显式挂一个
  /// 空监听保活，模拟真实页面 watch 的生命周期。
  void mount() {
    final sub = container.listen<CallHistoryState>(
      callHistoryListProvider('room-a'),
      (_, _) {},
    );
    addTearDown(sub.close);
  }

  /// 挂载 provider（触发 build + 延迟首屏 refresh）并等事件队列清空。
  Future<void> boot() async {
    mount();
    await pumpEventQueue();
  }

  CallHistoryState currentState() =>
      container.read(callHistoryListProvider('room-a'));

  Future<void> settle() => pumpEventQueue();

  CallHistoryList notifier() =>
      container.read(callHistoryListProvider('room-a').notifier);

  test('进页面触发首屏加载并填充条目与全量数（携带房间过滤）', () async {
    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m1', roomId: 'a')], total: 5),
    );
    await boot();

    final s = currentState();
    expect(s.entries.map((e) => e.messageId), ['m1']);
    expect(s.total, 5);
    expect(s.initialLoading, isFalse);
    expect(s.hasMore, isTrue);
    expect(s.error, isNull);
    expect(repository.requests.single.roomId, 'room-a');
    expect(repository.requests.single.orderBy, 'desc');
    expect(repository.requests.single.pageNum, 1);
  });

  test('空会话列表没有错误也没有更多页', () async {
    repository.enqueueSuccessful(CallHistoryPageData.empty);
    await boot();

    final s = currentState();
    expect(s.entries, isEmpty);
    expect(s.total, 0);
    expect(s.hasMore, isFalse);
    expect(s.error, isNull);
  });

  test('首屏失败时错误落位到 state，不抛出', () async {
    repository.enqueueFailure(const FormatException('bad response'));
    await boot();

    final s = currentState();
    expect(s.entries, isEmpty);
    expect(s.error, isA<FormatException>());
    expect(s.initialLoading, isFalse);
  });

  test('loadMore 按页追加且按 messageId 去重（房间过滤持续携带）', () async {
    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m1'), entry('m2')], total: 3),
    );
    await boot();

    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m2'), entry('m3')], total: 3),
    );
    await notifier().loadMore();
    await settle();

    final s = currentState();
    expect(s.entries.map((e) => e.messageId), ['m1', 'm2', 'm3']);
    expect(s.hasMore, isFalse);
    expect(s.loadingMore, isFalse);
    expect(
      repository.requests.map((r) => (r.pageNum, r.roomId)),
      [(1, 'room-a'), (2, 'room-a')],
    );
  });

  test('追加页失败时保留既有条目且仍可重试', () async {
    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m1')], total: 2),
    );
    await boot();

    repository.enqueueFailure(StateError('network down'));
    await notifier().loadMore();
    await settle();

    final s = currentState();
    expect(s.entries.map((e) => e.messageId), ['m1']);
    expect(s.loadingMore, isFalse);
    expect(s.hasMore, isTrue);
    expect(s.error, isNull);

    // 手动重试：消费下一个成功响应正常追加
    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m1'), entry('m2')], total: 2),
    );
    await notifier().loadMore();
    await settle();
    expect(currentState().entries.map((e) => e.messageId), ['m1', 'm2']);
    expect(currentState().hasMore, isFalse);
  });

  test('切换排序方向会重置列表并按新方向重拉', () async {
    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m1')], total: 1),
    );
    await boot();

    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m9')], total: 1),
    );
    await notifier().setOrderBy('asc');
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
    await boot();

    final pending = Completer<CallHistoryPageData>();
    repository.enqueuePending(pending);
    final loadMoreFuture = notifier().loadMore();

    repository.enqueueSuccessful(
      CallHistoryPageData(entries: [entry('m1')], total: 1),
    );
    final refreshFuture = notifier().refresh();

    // 追加页完成后才被丢弃：refresh 的 generation 更新使其过期
    pending.complete(
      CallHistoryPageData(entries: [entry('m1')], total: 1),
    );
    await Future.wait([loadMoreFuture, refreshFuture]);
    await settle();

    final s = currentState();
    expect(s.entries.map((e) => e.messageId), ['m1']);
    expect(s.total, 1);
    expect(s.loadingMore, isFalse);
    expect(repository.requests.map((r) => r.pageNum), [1, 2, 1]);
  });

  test('主框架侧栏不再包含通话记录页签（并入会话详情）', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final items = container.read(layoutControllerProvider).items;
    expect(items.map((i) => i.name), isNot(contains('sidebar_calls')));
    expect(items.first.name, 'sidebar_chat');
    expect(items.last.name, 'sidebar_setting');
  });
}

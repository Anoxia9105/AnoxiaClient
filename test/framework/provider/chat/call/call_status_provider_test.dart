import 'dart:async';

import 'package:anoxia/domain/repositories/call_repository.dart';
import 'package:anoxia/framework/domain/room_call_status.dart';
import 'package:anoxia/framework/provider/chat/call/call_status_provider.dart';
import 'package:anoxia/framework/provider/core/call_repository_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 手动完成 HTTP 响应，确定性地复现响应与实时事件的先后顺序。
class _PendingCallRepository implements CallRepository {
  final requests = <Completer<RoomCallStatus>>[];

  @override
  Future<RoomCallStatus> fetchCallStatus(String roomId) {
    final response = Completer<RoomCallStatus>();
    requests.add(response);
    return response.future;
  }

  @override
  Future<String> fetchCallToken(String roomId) => throw UnimplementedError();

  @override
  Future<bool> removeParticipant(String roomId, String identity) =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _PendingCallRepository repository;
  late ProviderContainer container;
  late CallStatusController controller;

  setUp(() {
    repository = _PendingCallRepository();
    container = ProviderContainer(
      overrides: [callRepositoryProvider.overrideWithValue(repository)],
    );
    controller = container.read(callStatusControllerProvider.notifier);
    addTearDown(container.dispose);
  });

  test('通话结束事件发生后，较早请求的通话中响应不能恢复加入通话状态', () async {
    controller.markStarted('group', startTime: 1000);
    final refresh = controller.refresh('group');

    controller.markEnded('group');
    repository.requests.single.complete(
      const RoomCallStatus(calling: true, startTime: 1000),
    );
    await refresh;

    final status = container.read(roomCallStatusProvider('group'));
    expect(status.calling, isFalse);
    expect(status.startTime, 0);
  });

  test('新通话开始事件发生后，较早请求的空闲响应不能隐藏进行中的通话', () async {
    final refresh = controller.refresh('group');

    controller.markStarted('group', startTime: 2000);
    repository.requests.single.complete(const RoomCallStatus.idle());
    await refresh;

    final status = container.read(roomCallStatusProvider('group'));
    expect(status.calling, isTrue);
    expect(status.startTime, 2000);
  });

  test('同一群新一轮通话开始后，旧请求不能覆盖新的开始时间', () async {
    controller.markStarted('group', startTime: 1000);
    final refresh = controller.refresh('group');

    controller.markEnded('group');
    controller.markStarted('group', startTime: 3000);
    repository.requests.single.complete(
      const RoomCallStatus(calling: true, startTime: 1000),
    );
    await refresh;

    expect(container.read(roomCallStatusProvider('group')).startTime, 3000);
  });

  test('已缓存的群通话状态仍可显式刷新为结束，覆盖锁屏期间过期的缓存', () async {
    controller.markStarted('group', startTime: 1000);
    await controller.ensureLoaded('group');
    expect(repository.requests, isEmpty);

    final refresh = controller.refresh('group');
    repository.requests.single.complete(const RoomCallStatus.idle());
    await refresh;

    expect(container.read(roomCallStatusProvider('group')).calling, isFalse);
  });

  test('其他房间的实时事件不会阻止当前房间接受刷新结果', () async {
    final refresh = controller.refresh('group');

    controller.markStarted('another-group', startTime: 4000);
    repository.requests.single.complete(
      const RoomCallStatus(calling: true, startTime: 1000),
    );
    await refresh;

    expect(container.read(roomCallStatusProvider('group')).startTime, 1000);
    expect(
      container.read(roomCallStatusProvider('another-group')).startTime,
      4000,
    );
  });

  testWidgets('锁屏期间群通话结束，恢复前台后自动校正缓存中的加入通话状态', (tester) async {
    controller.markStarted('group', startTime: 1000);
    await controller.ensureLoaded('group');
    expect(repository.requests, isEmpty);

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();

    expect(repository.requests, hasLength(1));
    repository.requests.single.complete(const RoomCallStatus.idle());
    await tester.pump();

    expect(container.read(roomCallStatusProvider('group')).calling, isFalse);
    expect(container.read(roomCallStatusProvider('group')).startTime, 0);
  });

  testWidgets('恢复前台时旧查询仍在进行，旧响应完成后必须补查锁屏期间的通话结束状态', (tester) async {
    controller.markStarted('group', startTime: 1000);
    final oldRefresh = controller.refresh('group');
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }

    repository.requests.first.complete(
      const RoomCallStatus(calling: true, startTime: 1000),
    );
    await oldRefresh;
    await tester.pump();

    expect(repository.requests, hasLength(2));
    repository.requests.last.complete(const RoomCallStatus.idle());
    await tester.pump();

    expect(container.read(roomCallStatusProvider('group')).calling, isFalse);
  });
}

import 'dart:async';
import 'package:anoxia/domain/repositories/message_repository.dart';
import 'package:anoxia/framework/domain/forward_message.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/message/forwarding_controller.dart';
import 'package:anoxia/framework/provider/core/message_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth extends AuthController {
  @override
  Future<UserInfo?> build() async => UserInfo.fromJson({'userId': 7});
  void simulateAccountChange() => state = AsyncData(UserInfo.fromJson({'userId': 8}));
}

class _Repository extends Fake implements MessageRepository {
  ForwardRequest? pending;
  final requests = <ForwardRequest>[];
  Object? error;
  Completer<ForwardResult>? gate;
  @override
  Future<ForwardRequest?> pendingForward(int userId) async => pending;
  @override
  Future<void> savePendingForward(int userId, ForwardRequest? request) async {
    pending = request;
  }

  @override
  Future<ForwardResult> forwardMessages(ForwardRequest request) async {
    requests.add(request);
    if (error != null) throw error!;
    if (gate != null) return gate!.future;
    return ForwardResult(
      operationId: 'op',
      targetRoomId: request.targetRoomId,
      status: 'SUCCEEDED',
      items: [
        const ForwardResultItem(messageId: 'm', seq: 4, status: 'SUCCEEDED'),
      ],
    );
  }
}

void main() {
  Future<ProviderContainer> setup(_Repository repository) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        messageRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    // 保持认证状态，模拟路由层对当前用户的持续订阅。
    final subscription = container.listen(authControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(authControllerProvider.future);
    return container;
  }

  test('等待结果期间切账号保留旧请求且不报告成功', () async {
    final repository = _Repository()..gate = Completer<ForwardResult>();
    final container = await setup(repository);
    final controller = container.read(forwardingControllerProvider.notifier);
    final result = controller.send('s', 't', ['one'], 'INDIVIDUAL');
    // 让本地保存与提交进入等待，再模拟账号改变。
    await Future<void>.delayed(Duration.zero);
    (container.read(authControllerProvider.notifier) as _Auth).simulateAccountChange();
    repository.gate!.complete(
      const ForwardResult(
        operationId: 'op',
        targetRoomId: 't',
        status: 'SUCCEEDED',
        items: [ForwardResultItem(messageId: 'm', seq: 1, status: 'SUCCEEDED')],
      ),
    );
    await expectLater(result, throwsStateError);
    expect(repository.pending, isNotNull);
  });
  test('网络结果未知保留请求，重试复用 requestId，成功清理', () async {
    final repository = _Repository()..error = TimeoutException('network');
    final container = await setup(repository);
    final controller = container.read(forwardingControllerProvider.notifier);
    await expectLater(
      controller.send('s', 't', ['one'], 'INDIVIDUAL'),
      throwsA(isA<TimeoutException>()),
    );
    final id = repository.pending!.requestId;
    repository.error = null;
    expect(
      (await controller.send('s', 't', ['one'], 'INDIVIDUAL')).isSuccess,
      isTrue,
    );
    expect(repository.requests.last.requestId, id);
    expect(repository.pending, isNull);
  });
  test('不同待确认请求阻止新转发，明确拒绝可清理', () async {
    final repository = _Repository()
      ..pending = const ForwardRequest(
        requestId: 'old',
        sourceRoomId: 's',
        targetRoomId: 'oldTarget',
        messageIds: ['one'],
        mode: 'INDIVIDUAL',
      );
    final container = await setup(repository);
    final controller = container.read(forwardingControllerProvider.notifier);
    await expectLater(
      controller.send('s', 'newTarget', ['one'], 'INDIVIDUAL'),
      throwsA(isA<PendingForwardException>()),
    );
    expect(repository.requests, isEmpty);
    repository.error = const ForwardRejectedException(403);
    await expectLater(
      controller.send('s', 'oldTarget', ['one'], 'INDIVIDUAL'),
      throwsA(isA<ForwardRejectedException>()),
    );
    expect(repository.pending, isNull);
  });
  test('不同并发请求不复用其他目标的结果', () async {
    final repository = _Repository()..gate = Completer<ForwardResult>();
    final container = await setup(repository);
    final controller = container.read(forwardingControllerProvider.notifier);
    final first = controller.send('s', 't', ['one'], 'INDIVIDUAL');
    await expectLater(
      controller.send('s', 'other', ['one'], 'INDIVIDUAL'),
      throwsA(isA<PendingForwardException>()),
    );
    repository.gate!.complete(
      const ForwardResult(
        operationId: 'op',
        targetRoomId: 't',
        status: 'SUCCEEDED',
        items: [ForwardResultItem(messageId: 'm', seq: 1, status: 'SUCCEEDED')],
      ),
    );
    expect((await first).targetRoomId, 't');
    expect(repository.requests.length, 1);
  });
}

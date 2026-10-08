import 'dart:async';
import 'package:anoxia/framework/domain/forward_message.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/core/message_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'forwarding_controller.g.dart';

class PendingForwardException implements Exception {}

class ForwardFailedException implements Exception {}

@Riverpod(keepAlive: true)
class ForwardingController extends _$ForwardingController {
  Future<ForwardResult>? _running;
  String? _runningKey;
  @override
  AsyncValue<ForwardResult?> build() => const AsyncData(null);

  Future<ForwardResult> send(
    String source,
    String target,
    List<String> ids,
    String mode, {
    bool resumePrevious = false,
  }) {
    final orderedIds = [...ids]..sort();
    final key = '$source/$target/$mode/$resumePrevious/${orderedIds.join(",")}';
    if (_running != null) {
      if (_runningKey != key) return Future.error(PendingForwardException());
      return _running!;
    }
    _runningKey = key;
    return _running = _send(source, target, ids, mode, resumePrevious)
        .whenComplete(() {
          _running = null;
          _runningKey = null;
        });
  }

  Future<ForwardResult> _send(
    String source,
    String target,
    List<String> ids,
    String mode,
    bool resumePrevious,
  ) async {
    final userId = ref.read(authControllerProvider).value?.userId;
    if (userId == null) throw StateError('Not authenticated');
    final repository = ref.read(messageRepositoryProvider);
    final pending = await repository.pendingForward(userId);
    _ensureSession(userId);
    if (pending != null &&
        !pending.matches(source, target, ids, mode) &&
        !resumePrevious) {
      throw PendingForwardException();
    }
    final request =
        pending ??
        ForwardRequest(
          requestId: const Uuid().v4(),
          sourceRoomId: source,
          targetRoomId: target,
          messageIds: ids,
          mode: mode,
        );
    await repository.savePendingForward(userId, request);
    _ensureSession(userId);
    state = const AsyncLoading();
    try {
      var result = await repository.forwardMessages(request);
      final deadline = DateTime.now().add(const Duration(seconds: 60));
      while (!result.isSuccess) {
        _ensureSession(userId);
        state = AsyncData(result);
        if (result.status == 'FAILED') throw ForwardFailedException();
        if (DateTime.now().isAfter(deadline)) {
          throw TimeoutException('Forward pending');
        }
        await Future<void>.delayed(const Duration(milliseconds: 700));
        _ensureSession(userId);
        result = await repository.forwardStatus(result.operationId);
      }
      _ensureSession(userId);
      await repository.savePendingForward(userId, null);
      _ensureSession(userId);
      state = AsyncData(result);
      return result;
    } catch (error, stack) {
      // 服务端明确拒绝的请求没有创建消息；可以安全解除本地待确认记录。
      if (error is ForwardRejectedException &&
          error.code >= 400 &&
          error.code < 500 &&
          ref.mounted &&
          ref.read(authControllerProvider).value?.userId == userId) {
        await repository.savePendingForward(userId, null);
      }
      if (ref.mounted &&
          ref.read(authControllerProvider).value?.userId == userId) {
        state = AsyncError(error, stack);
      }
      rethrow;
    }
  }

  void _ensureSession(int userId) {
    if (!ref.mounted ||
        ref.read(authControllerProvider).value?.userId != userId) {
      throw StateError('Session changed');
    }
  }
}

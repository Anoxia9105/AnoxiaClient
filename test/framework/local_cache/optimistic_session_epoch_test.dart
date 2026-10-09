import 'dart:async';

import 'package:anoxia/domain/repositories/chat_repository.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/local_cache/session_epoch.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/core/chat_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Messages extends ChatMessages {
  @override
  void build() {}
}

class _Repository extends Fake implements ChatRepository {
  final started = Completer<void>();
  final gate = Completer<void>();
  final cachedIds = <String?>[];

  @override
  Future<void> cacheLocalMessage(ChatMessage message) async {
    cachedIds.add(message.messageId);
    if (!started.isCompleted) started.complete();
    await gate.future;
  }
}

void main() {
  test('切账号后队列中旧消息被拒绝且不重新插入乐观缓存', () async {
    final repository = _Repository();
    final container = ProviderContainer(
      overrides: [
        chatMessagesProvider.overrideWith(_Messages.new),
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(chatMessagesProvider.notifier);
    notifier.upsertMessage(ChatMessage(messageId: 'first', roomId: 'room'));
    await repository.started.future;
    notifier.upsertMessage(ChatMessage(messageId: 'queued', roomId: 'room'));
    SessionEpoch.instance.advance();
    container.invalidate(optimisticRoomMessagesProvider);
    expect(container.read(optimisticRoomMessagesProvider), isEmpty);
    repository.gate.complete();
    // Drain both queue continuations and the rejection handler.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(repository.cachedIds, ['first']);
    expect(container.read(optimisticRoomMessagesProvider), isEmpty);
  });
}

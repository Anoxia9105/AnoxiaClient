import 'dart:async';

import 'package:anoxia/domain/repositories/chat_repository.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/provider/auth/token_provider.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/core/chat_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements ChatRepository {
  final messages = StreamController<List<ChatMessage>>.broadcast();
  int subscriptions = 0;

  @override
  Stream<List<ChatMessage>> watchMessages(
    String convId, {
    int? limit = 50,
    int offset = 0,
  }) {
    subscriptions++;
    return messages.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final empty in [false, true]) {
    test('切回已加载${empty ? '空' : ''}房间同步显示缓存，登出清除缓存', () async {
      final repository = _Repository();
      final container = ProviderContainer(
        overrides: [chatRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      addTearDown(repository.messages.close);
      container.read(tokenCacheProvider.notifier).setToken('session');
      final provider = roomMessagesProvider('room');
      final first = container.listen(provider, (_, _) {});
      final messages = empty
          ? <ChatMessage>[]
          : [ChatMessage(messageId: 'cached', roomId: 'room')];
      repository.messages.add(messages);
      await container.read(provider.future);
      first.close();
      await container.pump();

      final second = container.listen(provider, (_, _) {});
      expect(container.read(provider).hasValue, isTrue);
      expect(container.read(provider).value, messages);
      expect(repository.subscriptions, 1);

      container.read(tokenCacheProvider.notifier).clearToken();
      expect(await container.read(provider.future), isEmpty);
      second.close();
    });
  }
}

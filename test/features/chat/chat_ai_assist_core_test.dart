import 'dart:async';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/ai/chat_ai_assist_core.dart';
import 'package:anoxia/framework/network/sse_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('有增量但缺少 done 时保留部分内容并明确失败，不当作完整结果', () async {
    final frames = StreamController<SseFrame>(sync: true);
    final partial = <String>[];
    final completed = <String>[];
    final errors = <String>[];
    final health = <bool>[];
    final core = ChatAiAssistCore(transport: (_, {body}) => frames.stream);
    core.suggestReplies(
      input: const {},
      handlers: ChatAiStreamHandlers(
        onDelta: partial.add,
        onDone: (_, text) => completed.add(text),
        onError: errors.add,
        onSettled: health.add,
      ),
    );
    frames.add(SseFrame(data: '尚未完成的内容'));
    await frames.close();
    expect(partial, ['尚未完成的内容']);
    expect(completed, isEmpty);
    expect(errors, hasLength(1));
    expect(health, isEmpty);
    core.dispose();
  });
  for (final code in [
    'QUOTA_EXHAUSTED',
    'RATE_LIMITED',
    'INVALID_REQUEST',
    'FEATURE_DISABLED',
    'INTERNAL_ERROR',
    'UPSTREAM_ERROR',
  ]) {
    test('错误 $code 的健康分类与单次终态', () async {
      final frames = StreamController<SseFrame>(sync: true);
      final health = <bool>[];
      final errors = <String>[];
      final core = ChatAiAssistCore(transport: (_, {body}) => frames.stream);
      core.suggestReplies(
        input: const {},
        handlers: ChatAiStreamHandlers(
          onDelta: (_) {},
          onError: errors.add,
          onSettled: health.add,
        ),
      );
      frames.add(
        SseFrame(event: 'error', data: '{"message":"提示","code":"$code"}'),
      );
      frames.add(SseFrame(event: 'done', data: '{"text":"迟到结果"}'));
      expect(errors, code == 'RATE_LIMITED' ? ['chat_ai.retry_later'] : ['提示']);
      expect(health, code == 'UPSTREAM_ERROR' ? [false] : isEmpty);
      await frames.close();
      core.dispose();
    });
  }

  test('智能回复使用临时端点且不传会话 ID', () async {
    String? path;
    Object? request;
    final core = ChatAiAssistCore(
      transport: (p, {body}) {
        path = p;
        request = body;
        return const Stream.empty();
      },
    );
    core.suggestReplies(
      input: const {'draft': '周六不方便'},
      handlers: ChatAiStreamHandlers(onDelta: (_) {}, onError: (_) {}),
    );
    expect(path, '/chat/ai/replies/stream');
    expect((request as Map)['draft'], '周六不方便');
    expect(request, isNot(contains('conversationId')));
    core.dispose();
  });

  test('done 后取消节流回调，权威全文不会被旧增量覆盖', () async {
    final frames = StreamController<SseFrame>(sync: true);
    final output = <String>[];
    final core = ChatAiAssistCore(transport: (_, {body}) => frames.stream);
    core.suggestReplies(
      input: const {},
      handlers: ChatAiStreamHandlers(
        onDelta: output.add,
        onDone: (_, text) => output.add(text),
      ),
    );
    frames.add(SseFrame(data: 'partial'));
    frames.add(SseFrame(event: 'done', data: '{"text":"authoritative"}'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(output, ['authoritative']);
    await frames.close();
    core.dispose();
  });

  test('本地网络失败不会触发模型熔断', () async {
    final frames = StreamController<SseFrame>(sync: true);
    final health = <bool>[];
    final core = ChatAiAssistCore(transport: (_, {body}) => frames.stream);
    core.suggestReplies(
      input: const {},
      handlers: ChatAiStreamHandlers(
        onDelta: (_) {},
        onError: (_) {},
        onSettled: health.add,
      ),
    );
    frames.addError(StateError('offline'));
    expect(health, isEmpty);
    await frames.close();
    core.dispose();
  });
}

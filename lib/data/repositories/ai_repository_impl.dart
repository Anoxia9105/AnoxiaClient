import 'dart:convert';

import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/ai_stream_event.dart';
import 'package:anoxia/domain/repositories/ai_repository.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/framework/network/sse_client.dart';

/// AI 对话仓库实现
///
/// 通过 SSE 流式接口 `POST /chat/ai/stream` 提供 AI 对话。
/// 实现 [AiRepository] 抽象接口，供 UI 层 Provider 使用。
class AiRepositoryImpl implements AiRepository {
  /// 流式对话；[conversationId] 首次传 null，之后回传 done 里的值实现多轮记忆
  @override
  Stream<AiStreamEvent> askStream(String prompt, {String? conversationId}) async* {
    await for (final frame in SseClient.post(API.chatAiStream, body: {
      'message': prompt,
      if (conversationId != null && conversationId.isNotEmpty)
        'conversationId': conversationId,
    })) {
      if (!frame.isNamed) {
        yield AiDelta(frame.data);
        continue;
      }
      switch (frame.event!) {
        case 'thinking':
          yield AiThinking(frame.data == '[done]' ? null : frame.data);
        case 'done':
          try {
            final json = jsonDecode(frame.data) as Map<String, dynamic>;
            yield AiDone(
              json['conversationId'] as String?,
              json['text'] as String? ?? '',
              json['truncated'] as bool? ?? false,
            );
          } catch (_) {
            throw const AiException('AI请求失败 请稍后在试');
          }
        case 'error':
          String msg = 'AI请求失败 请稍后在试';
          try {
            msg =
                (jsonDecode(frame.data) as Map<String, dynamic>)['message']
                        as String? ??
                    msg;
          } catch (_) {}
          throw AiException(msg);
        default:
          break; // 忽略未来新增事件，保证向前兼容
      }
    }
  }

  @override
  @Deprecated('请使用 askStream')
  Future<String> ask(String prompt) async {
    // 兼容旧调用：聚合流式结果为完整文本
    final buf = StringBuffer();
    String? fallback;
    bool gotDone = false;
    try {
      await for (final ev in askStream(prompt)) {
        switch (ev) {
          case AiDelta(:final text):
            buf.write(text);
          case AiDone(:final text):
            gotDone = true;
            fallback = text;
          case AiThinking():
            break;
        }
      }
    } on AiException {
      rethrow;
    }
    if (gotDone && fallback != null && fallback.isNotEmpty) return fallback;
    final collected = buf.toString();
    if (collected.isNotEmpty) return collected;
    if (!gotDone) throw const AiException('AI请求失败 请稍后在试');
    return fallback ?? '';
  }

  /// 兼容旧接口的应急 HTTP 兜底（仅在 SSE 不可用时使用，当前已废弃）
  @Deprecated('仅兼容保留')
  Future<String> askViaGemini(String prompt) async {
    final resp = await DioClient().post(
      API.chatGemini,
      data: {'prompt': prompt},
    );
    if (resp.data['code'] != 200) {
      throw Exception(resp.data['msg'] ?? 'AI 请求失败');
    }
    return resp.data['data']['text'] ?? '';
  }
}

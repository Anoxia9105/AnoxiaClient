import 'dart:async';

import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../common/constants/API.dart';
import '../../domain/AiChatMessage.dart';
import '../../network/TokenManager.dart';

part 'ai_chat_controller.g.dart';

@riverpod
class AiChatController extends _$AiChatController {
  StreamSubscription? _subscription;

  @override
  List<AiChatMessage> build() {
    // ✅ Provider 销毁时，彻底关闭 SSE
    ref.onDispose(() {
      _closeSSE();
    });
    return [];
  }

  Future<void> askGemini(String prompt) async {
    if (prompt.trim().isEmpty) return;

    // 正在生成中，禁止再次发送
    if (state.isNotEmpty && state.last.isStreaming) return;

    _closeSSE();

    final userMsg = AiChatMessage(content: prompt, isAi: false);

    final aiMsg = AiChatMessage(content: "", isAi: true, isStreaming: true);

    state = [...state, userMsg, aiMsg];

    final token = await TokenManager.instance.getToken();
    final url =
        "${API.httpBaseUrl}/chat/gemini?prompt=${Uri.encodeComponent(prompt)}";

    _subscription =
        SSEClient.subscribeToSSE(
          method: SSERequestType.GET,
          url: url,
          header: {
            "Accept": "text/event-stream",
            "Authorization": "Bearer $token",
            "Cache-Control": "no-cache",
          },
        ).listen(
          (event) {
            final data = event.data;
            if (data == null) return;

            if (data.trim() == "[DONE]") {
              _finishStreaming();
              _closeSSE();
              return;
            }

            final last = state.last;
            if (!last.isStreaming) return;

            state = [
              ...state.sublist(0, state.length - 1),
              last.copyWith(content: last.content + data),
            ];
          },
          onDone: () {
            _finishStreaming();
            _closeSSE();
          },
          onError: (e) {
            print("错误=====================》》》》》》");
            final lastMsg = state.last;
            if (lastMsg.isAi) {
              state = [
                ...state.sublist(0, state.length - 1),
                lastMsg.copyWith(
                  content: "哎呀，Gemini 累了（请求过快），请稍后再试一次吧！",
                  isStreaming: false,
                ),
              ];
            }
            stopGenerating();
          },
          cancelOnError: true,
        );
  }

  /// 用户主动点击“停止”
  void stopGenerating() {
    _finishStreaming();
    _closeSSE();
  }

  void _finishStreaming() {
    if (state.isEmpty) return;
    final last = state.last;

    if (last.isAi && last.isStreaming) {
      state = [
        ...state.sublist(0, state.length - 1),
        last.copyWith(isStreaming: false),
      ];
    }
  }

  void _closeSSE() {
    _subscription?.cancel();
    _subscription = null;
    SSEClient.unsubscribeFromSSE();
  }
}

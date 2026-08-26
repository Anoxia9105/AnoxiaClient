import 'dart:async';

import 'package:anoxia/common/constants/storage_keys.dart';
import 'package:anoxia/common/utils/sp_util.dart';
import 'package:anoxia/domain/ai_stream_event.dart';
import 'package:anoxia/framework/domain/ai_chat_message.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/core/ai_repository_provider.dart';
import 'package:anoxia/framework/provider/core/toast_service_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_chat_controller.g.dart';

/// AI 对话控制器（SSE 流式）
///
/// 对接 `POST /chat/ai/stream`，与 `framework/network/sse_client.dart` 协议一致：
/// - thinking 命名事件（`[done]` 哨兵 = 思考结束）
/// - 匿名 data 为正文增量
/// - done / error 终态
/// - 多轮会话通过 `conversationId` 持久化（SharedPreferences per-user）
@riverpod
class AiChatController extends _$AiChatController {
  bool _loading = false;
  String? _conversationId;
  StreamSubscription<AiStreamEvent>? _sub;
  int _aiIndex = -1;
  final StringBuffer _thinkingBuf = StringBuffer();
  final StringBuffer _deltaBuf = StringBuffer();
  bool _gotDone = false;

  @override
  List<AiChatMessage> build() {
    // 异步恢复会话 ID（不阻塞首帧）
    _loadConversationId();
    ref.onDispose(() {
      _sub?.cancel();
    });
    // 监听账号切换：切号后会话 ID 已在 SessionResetService 中失效，需重载
    ref.listen(authControllerProvider, (prev, next) {
      final prevId = prev?.value?.userId;
      final nextId = next.value?.userId;
      if (prevId != nextId) {
        _conversationId = null;
        _loadConversationId();
      }
    });
    return [];
  }

  bool get isLoading => _loading;

  /// 当前会话 ID（用于续传多轮记忆）
  String? get conversationId => _conversationId;

  Future<void> _loadConversationId() async {
    try {
      final userId = ref.read(authControllerProvider).value?.userId;
      if (userId == null) return;
      final key = StorageKeys.aiConversationIdKey('$userId');
      final saved = SPUtil.instance.get(key);
      if (saved != null && saved.isNotEmpty) {
        _conversationId = saved;
      }
    } catch (_) {}
  }

  Future<void> _saveConversationId(String? id) async {
    try {
      final userId = ref.read(authControllerProvider).value?.userId;
      if (userId == null) return;
      final key = StorageKeys.aiConversationIdKey('$userId');
      if (id == null || id.isEmpty) {
        await SPUtil.instance.delete(key);
      } else {
        await SPUtil.instance.set(key, id);
      }
    } catch (_) {}
  }

  /// 清除会话记忆（开启新话题时调用）
  Future<void> clearConversation() async {
    _conversationId = null;
    await _saveConversationId(null);
  }

  /// 向 AI 发送消息（流式）
  ///
  /// 处理流程：
  /// 1. 插入用户消息与空 AI 占位（streaming: true）
  /// 2. 订阅 `askStream`，增量更新 AI 气泡
  ///    - thinking: 拼接到 thinking 区，ui 展示“思考中…”
  ///    - delta: 追加正文并清除思考提示
  ///    - done: 保存 conversationId、兜底全文、truncated 提示
  /// 3. error / 无 done 兜底：展示友好文案
  Future<void> ask(String prompt) async {
    if (prompt.trim().isEmpty || _loading) return;

    _loading = true;
    _gotDone = false;
    _thinkingBuf.clear();
    _deltaBuf.clear();

    // 1. 用户消息 + 占位 AI 消息
    state = [...state, AiChatMessage(content: prompt, isAi: false)];
    _aiIndex = state.length;
    state = [
      ...state,
      AiChatMessage(content: '', isAi: true, streaming: true, thinking: ''),
    ];

    void updateAiMessage({String? content, String? thinking, bool? clearThinking, bool? streaming}) {
      if (_aiIndex < 0 || _aiIndex >= state.length) return;
      final cur = state[_aiIndex];
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == _aiIndex)
            cur.copyWith(
              content: content,
              thinking: thinking,
              clearThinking: clearThinking ?? false,
              streaming: streaming,
            )
          else
            state[i],
      ];
    }

    try {
      final stream = ref.read(aiRepositoryProvider).askStream(
            prompt,
            conversationId: _conversationId,
          );

      final completer = Completer<void>();
      _sub?.cancel();
      _sub = stream.listen(
        (event) {
          switch (event) {
            case AiThinking(:final data):
              if (data == null) {
                // 思考结束哨兵
                _thinkingBuf.clear();
                updateAiMessage(clearThinking: true);
              } else {
                _thinkingBuf.write(data);
                // 思考增量实时展示在占位气泡里
                updateAiMessage(thinking: _thinkingBuf.toString());
              }
            case AiDelta(:final text):
              // 首个正文增量到来时清除思考态
              if (_thinkingBuf.isNotEmpty) {
                _thinkingBuf.clear();
                updateAiMessage(clearThinking: true);
              }
              _deltaBuf.write(text);
              updateAiMessage(content: _deltaBuf.toString());
            case AiDone(:final conversationId, :final text, :final truncated):
              _gotDone = true;
              if (conversationId != null && conversationId.isNotEmpty) {
                _conversationId = conversationId;
                unawaited(_saveConversationId(conversationId));
              }
              // 服务端权威全文兜底：若增量为空则用 done.text
              final finalText = _deltaBuf.isEmpty && text.isNotEmpty ? text : _deltaBuf.toString();
              // 若 finalText 仍空但 done 有文本（极端情况），直接使用 done.text
              final resolved = finalText.isNotEmpty ? finalText : text;
              // 思考不算成功：空正文视为失败
              if (resolved.isEmpty) {
                updateAiMessage(content: '⚠️ ${'chat_ai.failed'.tr()}', streaming: false, clearThinking: true);
                _loading = false;
                if (!completer.isCompleted) completer.completeError(const AiException('AI请求失败 请稍后在试'));
                return;
              }
              updateAiMessage(content: resolved, streaming: false, clearThinking: true);
              if (truncated) {
                ref.read(toastServiceProvider).showToast('chat_ai.truncated'.tr());
              }
              _loading = false;
              if (!completer.isCompleted) completer.complete();
          }
        },
        onError: (Object e) {
          _loading = false;
          final msg = e is AiException ? e.message : 'AI请求失败 请稍后在试';
          // 保留已收到的增量，仅在完全无内容时展示错误占位
          final collected = _deltaBuf.toString();
          if (collected.isEmpty) {
            updateAiMessage(content: '⚠️ $msg', streaming: false, clearThinking: true);
          } else {
            updateAiMessage(streaming: false, clearThinking: true);
            ref.read(toastServiceProvider).showToast(msg);
          }
          if (!completer.isCompleted) completer.completeError(e);
        },
        onDone: () {
          if (!_gotDone && _loading) {
            _loading = false;
            final collected = _deltaBuf.toString();
            if (collected.isEmpty) {
              // 无 done 即失败兜底
              updateAiMessage(content: '⚠️ AI请求失败 请稍后在试', streaming: false, clearThinking: true);
            } else {
              // 有增量但无 done：视为成功（网络提前断开但内容已完整）
              updateAiMessage(content: collected, streaming: false, clearThinking: true);
            }
          }
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: false,
      );

      await completer.future;
    } catch (e) {
      // 已在 onError 中处理展示，这里仅确保 loading 复位
      _loading = false;
      if (_aiIndex >= 0 && _aiIndex < state.length) {
        final cur = state[_aiIndex];
        if (cur.streaming) {
          updateAiMessage(streaming: false, clearThinking: true);
          if (cur.content.isEmpty) {
            final msg = e is AiException ? e.message : 'AI请求失败 请稍后在试';
            updateAiMessage(content: '⚠️ $msg');
          }
        }
      }
    } finally {
      _loading = false;
      _sub = null;
    }
  }

  /// 兼容旧命名（历史遗留 ChatGPT 直连 -> 现统一走 /chat/ai/stream）
  @Deprecated('请使用 ask')
  Future<void> askGemini(String prompt) => ask(prompt);

  /// 手动取消当前流（关闭面板时调用，中断上游并停止计费）
  void cancel() {
    _sub?.cancel();
    _sub = null;
    _loading = false;
    if (_aiIndex >= 0 && _aiIndex < state.length) {
      final cur = state[_aiIndex];
      if (cur.streaming) {
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == _aiIndex) cur.copyWith(streaming: false, clearThinking: true) else state[i],
        ];
      }
    }
  }

  /// 清空对话历史（同时保留或清除会话记忆由调用方决定）
  void clearHistory({bool keepConversation = true}) {
    cancel();
    state = [];
    _aiIndex = -1;
    if (!keepConversation) {
      clearConversation();
    }
  }
}

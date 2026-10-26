/// 聊天 AI 增强共享内核
///
/// 为「消息问AI」「输入框AI增强」提供统一的流式请求封装：
/// - 持久会话模式：POST /chat/ai/stream（可追问，conversationId 续传）
/// - 临时会话模式：POST /note/ai/stream（文本变换用完即删，不污染会话列表）
///
/// UI 只需提供 onDelta/onDone/onError 回调；内部处理节流、订阅生命周期与错误提取。
library;

import 'dart:async';
import 'dart:convert';

import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/domain/ai_stream_event.dart';
import 'package:anoxia/framework/network/sse_client.dart';
import 'package:anoxia/framework/provider/chat/message/ai_prompt_builder.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

/// 快捷动作定义（映射后端 NoteAiAction / 组合提示词）
enum ChatAiAction {
  explain,
  translate,
  summarize,
  polish,
  expand,
  continueWrite,
  simplify,
  custom,
}

extension ChatAiActionX on ChatAiAction {
  /// 是否走 /note/ai/stream 一次性动作端点（全部动作均为一次性文本变换）
  bool get isEphemeral => true;

  /// 后端 NoteAiAction 枚举名
  String get api => switch (this) {
    ChatAiAction.explain => 'CUSTOM',
    ChatAiAction.translate => 'TRANSLATE',
    ChatAiAction.summarize => 'SUMMARIZE',
    ChatAiAction.polish => 'POLISH',
    ChatAiAction.expand => 'EXPAND',
    ChatAiAction.continueWrite => 'CONTINUE',
    ChatAiAction.simplify => 'CUSTOM',
    ChatAiAction.custom => 'CUSTOM',
  };

  /// CUSTOM 动作的内置指令（后端 CUSTOM 必须携带 instruction）
  String? instruction(String? customText) => switch (this) {
    ChatAiAction.explain => 'ai_assist_explain_instruction'.tr(),
    ChatAiAction.simplify => 'ai_assist_simplify_instruction'.tr(),
    ChatAiAction.custom => customText ?? '',
    _ => null,
  };
}

/// 流式回调集合
class ChatAiStreamHandlers {
  const ChatAiStreamHandlers({
    required this.onDelta,
    this.onDone,
    this.onError,
    this.onThinking,
    this.onSettled,
  });

  /// 增量文本（core 内部 80ms 节流后回调全量累计文本）
  final void Function(String fullText) onDelta;

  /// 完成：conversationId（持久模式）/ 权威全文
  /// 新增 [truncated] 命名参数保持向后兼容，调用方可按需处理“回复过长已截断”提示
  final void Function(String conversationId, String fullText)? onDone;

  /// 失败（已提取服务端 message）
  final void Function(String message)? onError;

  /// 推理期增量（多次），[thinking] 为 null 表示思考结束 `[done]` 哨兵
  final void Function(String? thinking)? onThinking;

  /// 上游健康（单次最多一次）：true=拿到正文，false=明确的上游故障/空回复。
  /// 业务拒绝、网络故障、旧服务端未分类错误及主动取消均不触发。
  final void Function(bool success)? onSettled;
}

/// 共享流式控制器：一个实例对应一次弹窗生命周期
class ChatAiAssistCore {
  ChatAiAssistCore({
    Stream<SseFrame> Function(String path, {Object? body})? transport,
  }) : _transport = transport ?? SseClient.post;

  final Stream<SseFrame> Function(String path, {Object? body}) _transport;
  int _generation = 0;
  StreamSubscription<SseFrame>? _sub;
  final StringBuffer _buffer = StringBuffer();
  final StringBuffer _thinkingBuf = StringBuffer();
  Timer? _throttle;
  Timer? _thinkingThrottle;
  bool _streaming = false;

  bool get isStreaming => _streaming;

  /// 智能回复是聊天域的一次性任务，不传 conversationId，也不保存历史。
  void suggestReplies({
    required Map<String, String> input,
    required ChatAiStreamHandlers handlers,
  }) {
    _run(
      path: '/chat/ai/replies/stream',
      body: input,
      persistent: false,
      handlers: handlers,
    );
  }

  /// 输入框编辑：上下文与待处理文本分离，复用临时任务而不创建持久 AI 会话。
  void editDraft({
    required ChatAiAction action,
    required String content,
    required String draft,
    required String conversation,
    required String targetLang,
    required ChatAiStreamHandlers handlers,
  }) {
    transform(
      action: ChatAiAction.custom,
      content: jsonEncode({
        'conversation': conversation,
        if (draft != content) 'draft': draft,
        'target': content,
      }),
      customInstruction: buildChatEditInstruction(
        action.name,
        targetLang: targetLang,
      ),
      handlers: handlers,
    );
  }

  /// 持久会话聊天（/chat/ai/stream）：首问传 null conversationId，
  /// done 回调返回新 conversationId 供追问续传。
  void chat({
    required String message,
    String? conversationId,
    required ChatAiStreamHandlers handlers,
  }) {
    _run(
      path: '/chat/ai/stream',
      body: {
        'message': message,
        if (conversationId != null && conversationId.isNotEmpty)
          'conversationId': conversationId,
      },
      persistent: true,
      handlers: handlers,
    );
  }

  /// 一次性文本变换（/note/ai/stream）：临时会话用完即删。
  void transform({
    required ChatAiAction action,
    required String content,
    String? targetLang,
    String? customInstruction,
    required ChatAiStreamHandlers handlers,
  }) {
    final instruction = action.instruction(customInstruction);
    _run(
      path: '/note/ai/stream',
      body: {
        'action': action.api,
        'content': content,
        if (instruction != null && instruction.isNotEmpty)
          'instruction': instruction,
        if (action == ChatAiAction.translate &&
            targetLang != null &&
            targetLang.isNotEmpty)
          'targetLang': targetLang,
      },
      persistent: false,
      handlers: handlers,
    );
  }

  void _run({
    required String path,
    required Map<String, dynamic> body,
    required bool persistent,
    required ChatAiStreamHandlers handlers,
  }) {
    cancel();
    final generation = _generation;
    _buffer.clear();
    _thinkingBuf.clear();
    _streaming = true;
    var gotTerminal = false;
    var settled = false;

    void settle(bool success) {
      if (settled) return;
      settled = true;
      try {
        handlers.onSettled?.call(success);
      } catch (_) {}
    }

    void stopTimers() {
      _throttle?.cancel();
      _thinkingThrottle?.cancel();
    }

    void preservePartial() {
      if (_buffer.isNotEmpty) handlers.onDelta(_buffer.toString());
      _thinkingBuf.clear();
      handlers.onThinking?.call(null);
    }

    String failureMessage(AiException failure) => switch (failure.code) {
      'ENDPOINT_UNAVAILABLE' => 'chat_ai.server_upgrade_required'.tr(),
      'RATE_LIMITED' => 'chat_ai.retry_later'.tr(),
      _ => failure.message,
    };

    _sub = _transport(path, body: body).listen(
      (frame) {
        if (generation != _generation || gotTerminal) return;
        if (!frame.isNamed) {
          // 首个正文增量到来时，若仍有思考态则通知清空
          if (_thinkingBuf.isNotEmpty) {
            _thinkingBuf.clear();
            handlers.onThinking?.call(null);
          }
          _buffer.write(frame.data);
          _throttled(handlers);
          return;
        }
        switch (frame.event) {
          case 'thinking':
            if (frame.data == '[done]') {
              _thinkingBuf.clear();
              handlers.onThinking?.call(null);
            } else {
              _thinkingBuf.write(frame.data);
              _throttledThinking(handlers);
            }
          case 'done':
            stopTimers();
            gotTerminal = true;
            var full = _buffer.toString();
            var convId = '';
            var truncated = false;
            try {
              final json = jsonDecode(frame.data) as Map<String, dynamic>;
              final text = json['text'];
              if (text is String && text.isNotEmpty) full = text;
              if (persistent) convId = json['conversationId']?.toString() ?? '';
              truncated = json['truncated'] as bool? ?? false;
            } catch (_) {}
            _streaming = false;
            _thinkingBuf.clear();
            handlers.onThinking?.call(null);
            // 思考不算成功：空正文视为失败
            if (full.isEmpty) {
              handlers.onError?.call('chat_ai.failed'.tr());
              settle(false);
              return;
            }
            handlers.onDone?.call(convId, full);
            settle(true);
            if (truncated) {
              try {
                Toast.showToast(
                  'chat_ai.truncated'.tr(),
                  type: ToastType.warning,
                );
              } catch (_) {}
            }
          case 'error':
            stopTimers();
            gotTerminal = true;
            _streaming = false;
            _thinkingBuf.clear();
            handlers.onThinking?.call(null);
            var failure = AiException('chat_ai.failed'.tr());
            try {
              failure = AiException.fromPayload(
                jsonDecode(frame.data),
                fallback: 'chat_ai.failed'.tr(),
              );
            } catch (_) {}
            preservePartial();
            handlers.onError?.call(
              _buffer.isNotEmpty
                  ? '${failureMessage(failure)}\n${'chat_ai.incomplete'.tr()}'
                  : failureMessage(failure),
            );
            if (failure.isUpstreamFailure) {
              settle(false);
            } else {
              settled = true;
            }
        }
      },
      onError: (Object e) {
        if (generation != _generation || gotTerminal) return;
        gotTerminal = true;
        stopTimers();
        _streaming = false;
        var msg = 'chat_ai.failed'.tr();
        if (e is AiException) {
          if (e.message.isNotEmpty) msg = failureMessage(e);
        } else if (e is DioException) {
          final err = e.error?.toString();
          if (err != null && err.isNotEmpty && !err.startsWith('SSE HTTP')) {
            msg = err;
          }
        }
        preservePartial();
        handlers.onError?.call(
          _buffer.isNotEmpty ? 'chat_ai.incomplete'.tr() : msg,
        );
        if (e is AiException && e.isUpstreamFailure) {
          settle(false);
        } else {
          settled = true;
        }
      },
      onDone: () {
        if (generation != _generation) return;
        stopTimers();
        // 无 done/error 即断流兜底
        if (!gotTerminal && _streaming) {
          _streaming = false;
          preservePartial();
          handlers.onError?.call('chat_ai.incomplete'.tr());
          // 断流不得把部分正文当作完整结果，也不据此判定模型不可用。
          settled = true;
        }
      },
    );
  }

  void _throttled(ChatAiStreamHandlers handlers) {
    _throttle?.cancel();
    _throttle = Timer(const Duration(milliseconds: 80), () {
      handlers.onDelta(_buffer.toString());
    });
  }

  void _throttledThinking(ChatAiStreamHandlers handlers) {
    _thinkingThrottle?.cancel();
    _thinkingThrottle = Timer(const Duration(milliseconds: 80), () {
      handlers.onThinking?.call(_thinkingBuf.toString());
    });
  }

  /// 取消当前流（弹窗关闭/重新发起时调用）
  void cancel() {
    _generation++;
    _throttle?.cancel();
    _throttle = null;
    _thinkingThrottle?.cancel();
    _thinkingThrottle = null;
    _thinkingBuf.clear();
    _sub?.cancel();
    _sub = null;
    _streaming = false;
  }

  void dispose() => cancel();
}

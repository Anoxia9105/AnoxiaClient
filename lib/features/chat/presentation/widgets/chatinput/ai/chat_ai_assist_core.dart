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
import 'package:anoxia/framework/network/sse_client.dart';
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
        ChatAiAction.explain =>
          '用简洁易懂的中文解释这段内容的含义，包括潜在语气与言外之意。只输出解释本身。',
        ChatAiAction.simplify => '精简以下内容，去除冗余但保留全部关键信息。只输出精简结果。',
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
}

/// 共享流式控制器：一个实例对应一次弹窗生命周期
class ChatAiAssistCore {
  StreamSubscription<SseFrame>? _sub;
  final StringBuffer _buffer = StringBuffer();
  final StringBuffer _thinkingBuf = StringBuffer();
  Timer? _throttle;
  Timer? _thinkingThrottle;
  bool _streaming = false;

  bool get isStreaming => _streaming;

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
    _buffer.clear();
    _thinkingBuf.clear();
    _streaming = true;
    var gotTerminal = false;

    _sub = SseClient.post(path, body: body).listen(
      (frame) {
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
            handlers.onDone?.call(convId, full);
            if (truncated) {
              try {
                Toast.showToast('chat_ai.truncated'.tr(), type: ToastType.warning);
              } catch (_) {}
            }
          case 'error':
            gotTerminal = true;
            _streaming = false;
            _thinkingBuf.clear();
            handlers.onThinking?.call(null);
            var msg = '';
            try {
              final json = jsonDecode(frame.data) as Map<String, dynamic>;
              msg = json['message']?.toString() ?? '';
            } catch (_) {}
            handlers.onError?.call(
                msg.isEmpty ? 'chat_ai.failed'.tr() : msg);
        }
      },
      onError: (Object e) {
        _streaming = false;
        var msg = 'chat_ai.failed'.tr();
        if (e is DioException) {
          final err = e.error?.toString();
          if (err != null && err.isNotEmpty && !err.startsWith('SSE HTTP')) {
            msg = err;
          }
        }
        handlers.onError?.call(msg);
      },
      onDone: () {
        // 无 done/error 即断流兜底
        if (!gotTerminal && _streaming) {
          _streaming = false;
          if (_buffer.isEmpty) {
            handlers.onError?.call('chat_ai.failed'.tr());
          } else {
            handlers.onDone?.call('', _buffer.toString());
          }
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

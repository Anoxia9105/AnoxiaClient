/// AI 流式事件模型（对应服务端 SSE 协议）
///
/// 服务端协议（/chat/ai/stream 与 /note/ai/stream 一致）：
/// - `:keepalive` 注释行保活（SseClient 自动忽略）
/// - `event:thinking` + `data:<增量>` 多次，最后一条 `data:[done]` 为思考结束哨兵
/// - 匿名事件 `data:<正文增量>` 多次
/// - `event:done` + `data:{"conversationId","text","truncated"}` 终态
/// - `event:error` + `data:{"message"}` 失败
library;

/// AI 流式事件基类
sealed class AiStreamEvent {
  const AiStreamEvent();
}

/// 推理期增量
///
/// [data] 为 null 表示收到 `[done]` 哨兵，即思考结束。
class AiThinking extends AiStreamEvent {
  final String? data;
  const AiThinking(this.data);
}

/// 正文增量（匿名事件）
class AiDelta extends AiStreamEvent {
  final String text;
  const AiDelta(this.text);
}

/// 终态
///
/// [conversationId] 服务端返回的会话 ID，Flutter 需持久化后下次请求回传以实现多轮记忆。
/// [truncated] 为 true 表示回复过长已被截断，需提示用户。
class AiDone extends AiStreamEvent {
  final String? conversationId;
  final String text;
  final bool truncated;
  const AiDone(this.conversationId, this.text, this.truncated);
}

/// AI 业务异常
///
/// 覆盖三种服务端来源：AI 服务暂不可用（上游断开，可重试）、AI 调用失败: <详情>、今日 AI 用量已达上限...
/// 直接展示 [message] 即可。
class AiException implements Exception {
  final String message;
  const AiException(this.message);
  @override
  String toString() => message;
}

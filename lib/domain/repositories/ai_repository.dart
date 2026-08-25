import 'package:anoxia/domain/ai_stream_event.dart';

/// AI 对话仓库抽象接口
///
/// 定义 AI 聊天相关的远程数据操作契约。
/// 数据层通过实现此接口提供具体实现，UI 层 Provider 仅依赖此接口。
abstract interface class AiRepository {
  /// 流式对话；[conversationId] 首次传 null，之后回传 done 里的值实现多轮记忆
  ///
  /// 产出 [AiThinking] / [AiDelta] / [AiDone]，失败时抛 [AiException]。
  Stream<AiStreamEvent> askStream(String prompt, {String? conversationId});

  /// @Deprecated 遗留非流式接口，已废弃（恒失败），仅为兼容保留
  @Deprecated('请使用 askStream')
  Future<String> ask(String prompt);
}

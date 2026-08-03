import 'package:anoxia/domain/repositories/chat_repository.dart';
import 'package:anoxia/framework/domain/chat_message.dart';

/// 发送消息用例
///
/// 封装发送消息的业务逻辑：
/// 1. 确保消息有本地 ID（用于乐观更新）
/// 2. 标记为发送中（saving 到本地）
/// 3. 调用仓库发送消息
/// 4. 根据结果更新送达状态
///
/// 此用例不依赖任何 UI 代码，可直接在 Provider 或测试中使用。
class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  /// 发送单条消息
  /// [message] 待发送的消息对象
  /// 返回包含服务端返回信息的本地消息副本
  Future<ChatMessage> call(ChatMessage message) {
    return repository.sendMessage(message);
  }

  /// 重试发送失败的消息
  Future<void> retryPendingOutgoing() {
    return repository.retryPendingOutgoing();
  }
}

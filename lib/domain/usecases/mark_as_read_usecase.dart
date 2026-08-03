import 'package:anoxia/domain/repositories/chat_repository.dart';

/// 标记消息已读用例
///
/// 封装标记消息已读的业务逻辑。
/// 不应在 unreadCount 已经为 0 时调用 markAsRead（防抖优化）。
///
/// 此用例不依赖任何 UI 代码，可直接在 Provider 或测试中使用。
class MarkAsReadUseCase {
  final ChatRepository repository;

  MarkAsReadUseCase(this.repository);

  /// 标记指定会话的消息为已读
  /// [conversationId] 会话 ID
  /// [messageId] 指定消息 ID（可选）
  /// [seq] 指定消息序号（可选）
  Future<void> call(
    String conversationId, {
    String? messageId,
    int? seq,
  }) {
    return repository.markAsRead(
      conversationId,
      messageId: messageId,
      seq: seq,
    );
  }
}

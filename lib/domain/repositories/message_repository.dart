import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/message_search_result.dart';

/// 消息仓库抽象接口
///
/// 定义消息相关的远程数据操作契约：历史消息、撤回消息和消息搜索。
/// 数据层通过实现此接口提供具体实现，UI 层 Provider 仅依赖此接口。
abstract interface class MessageRepository {
  /// 获取历史消息
  ///
  /// [roomId] 房间 ID
  /// [beforeSeq] 加载早于此序号的历史消息
  /// [pageSize] 每页条数
  ///
  /// 返回历史消息列表；后端无更多数据时返回空列表。
  Future<List<ChatMessage>> fetchHistory(
    String roomId, {
    required int beforeSeq,
    required int pageSize,
  });

  /// 撤回消息
  ///
  /// [messageId] 目标消息 ID
  ///
  /// 返回是否操作成功。
  Future<bool> recallMessage(String messageId);

  /// 搜索消息
  ///
  /// [roomId] 房间 ID
  /// [keyword] 搜索关键词
  /// [contextSize] 上下文窗口大小
  Future<MessageSearchResult> searchMessages(
    String roomId,
    String keyword, {
    required int contextSize,
  });
}

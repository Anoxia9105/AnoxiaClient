import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/message_search_result.dart';
import 'package:anoxia/framework/domain/forward_message.dart';

/// 消息仓库抽象接口
///
/// 定义消息历史、搜索、转发及转发请求恢复的操作契约。
/// 数据层通过实现此接口提供具体实现，UI 层 Provider 仅依赖此接口。
abstract interface class MessageRepository {
  Future<ForwardResult> forwardMessages(ForwardRequest request);
  Future<ForwardResult> forwardStatus(String operationId);
  Future<ForwardRecordPage> forwardRecord(
    String recordId,
    String targetMessageId,
    String targetRoomId, {
    int offset = 0,
  });
  Future<ForwardRequest?> pendingForward(int userId);
  Future<void> savePendingForward(int userId, ForwardRequest? request);

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

  /// 表情回应补拉（进房按消息窗口批量拉取聚合）
  ///
  /// [roomId] 房间 ID
  /// [messageIds] 当前已加载的消息窗口（服务端去重截断 200 条）
  ///
  /// 返回按 (messageId, emoji) 聚合的行（count 总数 + mine 请求者视角）。
  /// 非房间成员或入参为空时返回空列表。
  Future<List<({String messageId, String emoji, int count, bool mine})>>
  fetchReactions(String roomId, List<String> messageIds);

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

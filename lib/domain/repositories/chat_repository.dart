import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';

/// 聊天仓库抽象接口
///
/// 定义聊天相关的数据操作契约。
/// 数据层通过实现此接口提供具体实现，领域层（用例）和 UI 层（Provider）
/// 仅依赖此接口，实现与数据源的解耦。
abstract interface class ChatRepository {
  /// 观察会话列表流
  Stream<List<ChatRoomVO>> watchConversations();

  /// 获取会话列表
  /// [sync] 是否在返回本地数据的同时触发后台同步
  Future<List<ChatRoomVO>> getConversations({bool sync = true});

  /// 同步会话列表
  Future<void> syncConversations();

  /// 观察指定会话的消息流
  Stream<List<ChatMessage>> watchMessages(
    String convId, {
    int? limit,
    int offset,
  });

  /// 获取指定会话的消息列表
  /// [limit] 每页条数；[offset] 偏移量；[beforeSeq] 加载早于此序号的历史消息
  Future<List<ChatMessage>> getMessagesForConversation(
    String convId, {
    int limit,
    int offset,
    int? beforeSeq,
    bool sync,
  });

  /// 同步指定会话的消息
  Future<void> syncMessages(String convId, {DateTime? since});

  /// 缓存传入的消息
  Future<void> cacheIncomingMessage(ChatMessage message);

  /// 缓存本地生成的消息
  Future<void> cacheLocalMessage(ChatMessage message);

  /// 网络恢复时触发同步
  Future<void> onNetworkRecovered();
}

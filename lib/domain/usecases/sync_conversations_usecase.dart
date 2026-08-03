import 'package:anoxia/domain/repositories/chat_repository.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';

/// 同步会话用例
///
/// 封装获取会话列表的业务逻辑：
/// 1. 返回本地缓存的会话列表（立即返回）
/// 2. 触发后台同步以获取最新数据
///
/// 此用例不依赖任何 UI 代码，可直接在 Provider 或测试中使用。
class SyncConversationsUseCase {
  final ChatRepository repository;

  SyncConversationsUseCase(this.repository);

  /// 获取会话列表
  /// [sync] 是否在返回本地数据的同时触发后台同步
  Future<List<ChatRoomVO>> call({bool sync = true}) {
    return repository.getConversations(sync: sync);
  }

  /// 观察会话列表流
  Stream<List<ChatRoomVO>> watch() {
    return repository.watchConversations();
  }

  /// 主动同步会话列表
  Future<void> sync() {
    return repository.syncConversations();
  }
}

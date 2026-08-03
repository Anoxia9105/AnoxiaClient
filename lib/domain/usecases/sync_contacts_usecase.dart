import 'package:anoxia/domain/repositories/contact_repository.dart';
import 'package:anoxia/framework/domain/chat_contact_vo.dart';

/// 同步联系人用例
///
/// 封装从远程获取联系人并写入本地缓存的业务逻辑。
/// 返回远程获取的联系人列表。
class SyncContactsUseCase {
  final ContactRepository repository;

  SyncContactsUseCase(this.repository);

  /// 从远程获取联系人并写入本地缓存
  /// [syncLocal] 是否在获取到远程数据后写入本地缓存
  Future<List<ChatContactVO>> call({bool syncLocal = true}) async {
    final contacts = await repository.fetchRemoteContacts();
    if (syncLocal) {
      await repository.upsertContacts(contacts);
    }
    return contacts;
  }

  /// 观察本地联系人列表流
  Stream<List<ChatContactVO>> watchLocal() {
    return repository.watchContacts();
  }

  /// 获取本地缓存的联系人列表
  /// [fallbackToRemote] 当本地为空时是否从远程获取
  Future<List<ChatContactVO>> getLocal({bool fallbackToRemote = false}) async {
    final local = await repository.getLocalContacts();
    if (local.isNotEmpty) return local;
    if (fallbackToRemote) {
      return await call(syncLocal: true);
    }
    return local;
  }
}

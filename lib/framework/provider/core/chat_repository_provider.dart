import 'package:anoxia/domain/repositories/chat_repository.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 聊天仓库 Provider
///
/// 提供 [ChatRepository] 接口的实现，供领域层用例和 UI 层 Provider 使用。
/// 数据层通过 [SyncRepository] 实现仓库接口，UI 层不直接依赖数据源。
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ref.watch(syncRepositoryProvider);
});

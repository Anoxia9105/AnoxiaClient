import 'package:anoxia/data/repositories/contact_repository_impl.dart';
import 'package:anoxia/domain/repositories/contact_repository.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 联系人仓库 Provider
///
/// 提供 [ContactRepository] 接口的实现，供领域层用例和 UI 层 Provider 使用。
final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  final local = ref.watch(localDataSourceProvider);
  return ContactRepositoryImpl(local: local);
});

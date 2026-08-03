import 'package:anoxia/data/repositories/group_repository_impl.dart';
import 'package:anoxia/domain/repositories/group_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 群组仓库 Provider
///
/// 提供 [GroupRepository] 接口的实现，供 UI 层 Provider 使用。
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepositoryImpl();
});

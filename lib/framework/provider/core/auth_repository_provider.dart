import 'package:anoxia/data/repositories/auth_repository_impl.dart';
import 'package:anoxia/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 认证仓库 Provider
///
/// 提供 [AuthRepository] 接口的实现，供领域层用例和 UI 层 Provider 使用。
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

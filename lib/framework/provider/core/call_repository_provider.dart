import 'package:anoxia/data/repositories/call_repository_impl.dart';
import 'package:anoxia/domain/repositories/call_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 通话仓库 Provider
///
/// 提供 [CallRepository] 接口的实现，供 UI 层 Provider 使用。
final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepositoryImpl();
});

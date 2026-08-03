import 'package:anoxia/data/repositories/ai_repository_impl.dart';
import 'package:anoxia/domain/repositories/ai_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI 对话仓库 Provider
///
/// 提供 [AiRepository] 接口的实现，供 UI 层 Provider 使用。
final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepositoryImpl();
});

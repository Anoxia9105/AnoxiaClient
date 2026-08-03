import 'package:anoxia/domain/usecases/mark_as_read_usecase.dart';
import 'package:anoxia/framework/provider/core/chat_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 标记已读用例 Provider
final markAsReadUseCaseProvider = Provider<MarkAsReadUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return MarkAsReadUseCase(repository);
});

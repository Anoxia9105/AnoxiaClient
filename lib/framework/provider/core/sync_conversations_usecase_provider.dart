import 'package:anoxia/domain/usecases/sync_conversations_usecase.dart';
import 'package:anoxia/framework/provider/core/chat_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 同步会话用例 Provider
final syncConversationsUseCaseProvider =
    Provider<SyncConversationsUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return SyncConversationsUseCase(repository);
});

import 'package:anoxia/domain/usecases/send_message_usecase.dart';
import 'package:anoxia/framework/provider/core/chat_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 发送消息用例 Provider
final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return SendMessageUseCase(repository);
});

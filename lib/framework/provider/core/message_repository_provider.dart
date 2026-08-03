import 'package:anoxia/data/repositories/message_repository_impl.dart';
import 'package:anoxia/domain/repositories/message_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 消息仓库 Provider
///
/// 提供 [MessageRepository] 接口的实现，供 UI 层 Provider 使用。
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepositoryImpl();
});

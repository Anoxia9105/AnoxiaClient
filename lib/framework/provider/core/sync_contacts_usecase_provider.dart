import 'package:anoxia/domain/usecases/sync_contacts_usecase.dart';
import 'package:anoxia/framework/provider/core/contact_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 同步联系人用例 Provider
final syncContactsUseCaseProvider = Provider<SyncContactsUseCase>((ref) {
  final repository = ref.watch(contactRepositoryProvider);
  return SyncContactsUseCase(repository);
});

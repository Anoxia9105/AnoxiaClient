import 'package:anoxia/domain/repositories/contact_repository.dart';
import 'package:anoxia/domain/usecases/sync_contacts_usecase.dart';
import 'package:anoxia/framework/domain/chat_contact_vo.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/provider/auth/token_provider.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/core/sync_contacts_usecase_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Contacts implements ContactRepository {
  bool fail = true;
  @override
  Future<List<ChatContactVO>> fetchRemoteContacts() async {
    if (fail) throw StateError('offline');
    return [];
  }

  @override
  Future<void> upsertContacts(List<ChatContactVO> contacts) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('首次失败向分组层传递错误，重试失败不挂起，成功后显示空列表', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final remote = _Contacts();
    final container = ProviderContainer(
      overrides: [
        localDataSourceProvider.overrideWithValue(LocalDataSource(db)),
        syncContactsUseCaseProvider.overrideWithValue(
          SyncContactsUseCase(remote),
        ),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    container.read(tokenCacheProvider.notifier).setToken('session');
    final listener = container.listen(sortedContactGroupsProvider, (_, _) {});
    addTearDown(listener.close);
    await expectLater(
      container.read(sortedContactGroupsProvider.future),
      throwsStateError,
    );
    expect(container.read(contactListServiceProvider).hasError, isTrue);
    await container.read(contactListServiceProvider.notifier).refresh();
    expect(container.read(contactListServiceProvider).isLoading, isFalse);
    expect(container.read(contactListServiceProvider).hasError, isTrue);
    remote.fail = false;
    await container.read(contactListServiceProvider.notifier).refresh();
    expect(await container.read(sortedContactGroupsProvider.future), isEmpty);
    remote.fail = true;
    final refresh = container
        .read(contactListServiceProvider.notifier)
        .refresh();
    expect(container.read(contactListServiceProvider).hasValue, isTrue);
    await refresh;
    expect(container.read(contactListServiceProvider).value, isEmpty);
    expect(container.read(contactRefreshFailedProvider), isTrue);
  });
}

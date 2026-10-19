// P0-1 输入草稿 store 单元测试。
//
// 覆盖（对应计划验收）：
// - 批量快速输入只落一次盘（debounce 合并，ContentingLocalDataSource 计数）；
// - debounce 窗口内不落盘、触发后写的是最新内容；
// - 内容与最近一次已落盘一致时重复 save 不再触发写盘；
// - flush（切房间）不等 debounce 立即落盘；
// - clear（发送成功路径）取消排队写入并删除行；
// - 空 delta 落盘时转为删行；
// - load 读取与失败降级。
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/local_cache/session_epoch.dart';
import 'package:anoxia/framework/provider/chat/input/input_draft_store_provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 计数版数据源：直接观察「落盘次数」。
class CountingLocalDataSource extends LocalDataSource {
  CountingLocalDataSource(super.db, {super.sessionEpoch});

  int saveCount = 0;
  int clearCount = 0;

  @override
  Future<void> saveInputDraft({
    required String roomId,
    required String deltaJson,
    required String plainText,
  }) {
    saveCount++;
    return super.saveInputDraft(
      roomId: roomId,
      deltaJson: deltaJson,
      plainText: plainText,
    );
  }

  @override
  Future<void> clearInputDraft(String roomId) {
    clearCount++;
    return super.clearInputDraft(roomId);
  }
}

/// 在 fakeAsync 里同步推动一个 Future 到完成（微任务已全部出队）。
T pump<T>(FakeAsync async, Future<T> future) {
  late Object? value;
  late Object error;
  var completed = false;
  var failed = false;
  future.then(
    (result) {
      value = result;
      completed = true;
    },
    onError: (Object e) {
      error = e;
      failed = true;
    },
  );
  var guard = 0;
  while (!(completed || failed) && guard++ < 200) {
    async.flushMicrotasks();
  }
  if (failed) {
    throw error;
  }
  return value as T;
}

void main() {
  test('批量快速输入只落一次盘，触发后写最新内容', () {
    fakeAsync((async) {
      final dataSource = CountingLocalDataSource(
        AppDatabase(NativeDatabase.memory()),
        sessionEpoch: SessionEpoch.instance,
      );
      final container = ProviderContainer(
        overrides: [localDataSourceProvider.overrideWith((ref) => dataSource)],
      );
      final store = container.read(inputDraftStoreProvider.notifier);

      store.save(
        roomId: 'r1',
        deltaJson: '[{"insert":"A\\n"}]',
        plainText: 'A',
      );
      store.save(
        roomId: 'r1',
        deltaJson: '[{"insert":"AB\\n"}]',
        plainText: 'AB',
      );
      store.save(
        roomId: 'r1',
        deltaJson: '[{"insert":"ABC\\n"}]',
        plainText: 'ABC',
      );

      // debounce 窗口内：未落盘
      expect(dataSource.saveCount, 0);
      expect(pump<InputDraft?>(async, dataSource.loadInputDraft('r1')), isNull);

      async.elapse(InputDraftStore.saveDebounce);
      pump(async, store.flush('r1')); // 收口写链，读库前保证已提交
      expect(dataSource.saveCount, 1);
      final row = pump<InputDraft?>(async, dataSource.loadInputDraft('r1'));
      expect(row!.plainText, 'ABC');
      expect(row.deltaJson, '[{"insert":"ABC\\n"}]');

      // 内容与最近一次已落盘一致：重复 save 不再写
      store.save(
        roomId: 'r1',
        deltaJson: '[{"insert":"ABC\\n"}]',
        plainText: 'ABC',
      );
      async.elapse(InputDraftStore.saveDebounce);
      pump(async, store.flush('r1'));
      expect(dataSource.saveCount, 1);

      // 第二个会话独立成行
      store.save(
        roomId: 'r2',
        deltaJson: '[{"insert":"X\\n"}]',
        plainText: 'X',
      );
      async.elapse(InputDraftStore.saveDebounce);
      pump(async, store.flush('r2'));
      expect(dataSource.saveCount, 2);
      final r1Row = pump<InputDraft?>(async, dataSource.loadInputDraft('r1'));
      final r2Row = pump<InputDraft?>(async, dataSource.loadInputDraft('r2'));
      expect(r1Row!.plainText, 'ABC');
      expect(r2Row!.plainText, 'X');

      container.dispose();
      pump(async, dataSource.db.close());
    });
  });

  test('flush（切房间）立即落盘，不等 debounce', () {
    fakeAsync((async) {
      final dataSource = CountingLocalDataSource(
        AppDatabase(NativeDatabase.memory()),
        sessionEpoch: SessionEpoch.instance,
      );
      final container = ProviderContainer(
        overrides: [localDataSourceProvider.overrideWith((ref) => dataSource)],
      );
      final store = container.read(inputDraftStoreProvider.notifier);

      store.save(
        roomId: 'r1',
        deltaJson: '[{"insert":"A\\n"}]',
        plainText: 'A',
      );
      pump(async, store.flush('r1'));
      var row = pump<InputDraft?>(async, dataSource.loadInputDraft('r1'));
      expect(dataSource.saveCount, 1);
      expect(row!.plainText, 'A');

      // flush 后再次输入仍可保存
      store.save(
        roomId: 'r1',
        deltaJson: '[{"insert":"B\\n"}]',
        plainText: 'B',
      );
      pump(async, store.flush('r1'));
      row = pump<InputDraft?>(async, dataSource.loadInputDraft('r1'));
      expect(dataSource.saveCount, 2);
      expect(row!.plainText, 'B');

      container.dispose();
      pump(async, dataSource.db.close());
    });
  });

  test('clear（发送成功路径）取消排队写入并删除行', () {
    fakeAsync((async) {
      final dataSource = CountingLocalDataSource(
        AppDatabase(NativeDatabase.memory()),
        sessionEpoch: SessionEpoch.instance,
      );
      final container = ProviderContainer(
        overrides: [localDataSourceProvider.overrideWith((ref) => dataSource)],
      );
      final store = container.read(inputDraftStoreProvider.notifier);

      pump(async, store.clear('r1')); // 收口写链，读库前保证删除已提交
      expect(pump<InputDraft?>(async, dataSource.loadInputDraft('r1')), isNull);
      expect(dataSource.clearCount, 1);
      expect(dataSource.saveCount, 0);

      // clear 之后仍可正常保存
      store.save(
        roomId: 'r1',
        deltaJson: '[{"insert":"C\\n"}]',
        plainText: 'C',
      );
      async.elapse(InputDraftStore.saveDebounce);
      pump(async, store.flush('r1'));
      expect(
        pump<InputDraft?>(async, dataSource.loadInputDraft('r1'))!.plainText,
        'C',
      );

      container.dispose();
      pump(async, dataSource.db.close());
    });
  });

  test('空 delta 在落盘时转为删除草稿行', () {
    fakeAsync((async) {
      final dataSource = CountingLocalDataSource(
        AppDatabase(NativeDatabase.memory()),
        sessionEpoch: SessionEpoch.instance,
      );
      final container = ProviderContainer(
        overrides: [localDataSourceProvider.overrideWith((ref) => dataSource)],
      );
      final store = container.read(inputDraftStoreProvider.notifier);

      store.save(
        roomId: 'r1',
        deltaJson: '[{"insert":"A\\n"}]',
        plainText: 'A',
      );
      async.elapse(InputDraftStore.saveDebounce);
      pump(async, store.flush('r1')); // 收口写链，读库前保证已提交
      final before = pump<InputDraft?>(async, dataSource.loadInputDraft('r1'));
      expect(before, isNotNull);

      // 用户清空输入（文档回到只有初始换行）
      store.save(roomId: 'r1', deltaJson: '[{"insert":"\\n"}]', plainText: '');
      async.elapse(InputDraftStore.saveDebounce);
      pump(async, store.flush('r1'));
      expect(dataSource.clearCount, 1);
      expect(pump<InputDraft?>(async, dataSource.loadInputDraft('r1')), isNull);

      container.dispose();
      pump(async, dataSource.db.close());
    });
  });

  test('load：有草稿返回内容，读取失败降级 null', () async {
    final dataSource = CountingLocalDataSource(
      AppDatabase(NativeDatabase.memory()),
      sessionEpoch: SessionEpoch.instance,
    );
    final container = ProviderContainer(
      overrides: [localDataSourceProvider.overrideWith((ref) => dataSource)],
    );
    final store = container.read(inputDraftStoreProvider.notifier);
    addTearDown(container.dispose);
    addTearDown(dataSource.db.close);

    expect(await store.load('r1'), isNull);

    await dataSource.db
        .into(dataSource.db.inputDrafts)
        .insert(
          InputDraftsCompanion.insert(
            roomId: 'r1',
            deltaJson: const Value('[{"insert":"草稿\\n"}]'),
            plainText: const Value('草稿'),
            updatedAt: DateTime.now(),
          ),
        );
    final draft = await store.load('r1');
    expect(draft!.plainText, '草稿');

    // 数据源不可用（库已关闭）→ 降级 null 而不是抛错
    await dataSource.db.close();
    expect(await store.load('r9'), isNull);
  });
}

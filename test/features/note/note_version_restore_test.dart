import 'dart:async';

import 'package:anoxia/domain/repositories/note_repository.dart';
import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/domain/note_tree.dart';
import 'package:anoxia/framework/provider/core/note_repository_provider.dart';
import 'package:anoxia/framework/provider/note/note_content_provider.dart';
import 'package:anoxia/framework/provider/note/note_version_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const original = NoteDoc(
  id: 1,
  folderId: null,
  title: '当前内容',
  content: '[{"insert":"当前内容\\n"}]',
  plainText: '当前内容\n',
  createdAt: null,
  updatedAt: null,
);
final historical = original.copyWith(
  title: '历史标题',
  content: '[{"insert":"历史正文\\n"}]',
  plainText: '历史正文\n',
);

class _NoteRepository extends Fake implements NoteRepository {
  NoteDoc stored = original;
  Completer<bool>? pendingSave;
  Completer<void>? pendingRestore;
  int restoreCalls = 0;
  int saveCalls = 0;
  bool restoreOk = true;

  @override
  Future<bool> saveNote(
    int noteId, {
    String? title,
    String? content,
    String? plainText,
  }) async {
    saveCalls++;
    if (pendingSave != null) await pendingSave!.future;
    stored = stored.copyWith(
      title: title,
      content: content,
      plainText: plainText,
    );
    return true;
  }

  @override
  Future<bool> restoreVersion(int noteId, int version) async {
    restoreCalls++;
    if (pendingRestore != null) await pendingRestore!.future;
    if (!restoreOk) return false;
    stored = historical;
    return true;
  }

  @override
  Future<NoteDoc> getNote(int noteId) async => stored;

  @override
  Future<NoteTree> getTree() async => NoteTree.fromJson(const {});

  @override
  Future<List<NoteDocVersion>> getVersions(int noteId) async => [];
}

void main() {
  test('还原必须等待正在提交的自动保存，避免旧内容覆盖历史版本', () async {
    final repo = _NoteRepository()..pendingSave = Completer<bool>();
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final session = container.read(noteSessionServiceProvider.notifier)
      ..open(original);
    final generation = container.read(noteSessionServiceProvider)!.generation;
    session.updateTitle('尚未保存的标题');
    final save = session.save();
    final restore = container
        .read(noteVersionServiceProvider.notifier)
        .restore(1, 1);
    await Future<void>.delayed(Duration.zero);
    expect(repo.restoreCalls, 0);
    repo.pendingSave!.complete(true);
    await save;
    expect(await restore, isTrue);
    expect(repo.stored.content, historical.content);
    expect(container.read(noteSessionServiceProvider)!.title, historical.title);
    expect(container.read(noteSessionServiceProvider)!.dirty, isFalse);
    expect(
      container.read(noteSessionServiceProvider)!.generation,
      greaterThan(generation),
    );
    await session.save();
    expect(repo.saveCalls, 1);
  });

  test('还原期间旧编辑器的变更与防抖保存不能写回', () async {
    final repo = _NoteRepository()..pendingRestore = Completer<void>();
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final session = container.read(noteSessionServiceProvider.notifier)
      ..open(original);
    final restore = container
        .read(noteVersionServiceProvider.notifier)
        .restore(1, 1);
    await Future<void>.delayed(Duration.zero);
    session.updateContent(content: original.content, plainText: '旧编辑器回调');
    await session.save();
    expect(repo.saveCalls, 0);
    repo.pendingRestore!.complete();
    expect(await restore, isTrue);
    expect(
      container.read(noteSessionServiceProvider)!.content,
      historical.content,
    );
    expect(container.read(noteSessionServiceProvider)!.dirty, isFalse);
  });

  test('服务端拒绝还原时保留原会话并返回失败', () async {
    final repo = _NoteRepository()..restoreOk = false;
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final session = container.read(noteSessionServiceProvider.notifier)
      ..open(original);
    final before = container.read(noteSessionServiceProvider);
    expect(
      await container.read(noteVersionServiceProvider.notifier).restore(1, 1),
      isFalse,
    );
    expect(container.read(noteSessionServiceProvider), same(before));
    session.updateTitle('失败后仍可编辑');
    expect(await session.save(), isTrue);
    expect(repo.stored.title, '失败后仍可编辑');
  });

  test('旧会话保存完成不能污染新打开的会话', () async {
    final repo = _NoteRepository()..pendingSave = Completer<bool>();
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final session = container.read(noteSessionServiceProvider.notifier)
      ..open(original);
    session.updateTitle('旧会话改动');
    final saving = session.save();
    session.open(historical);
    final reloaded = container.read(noteSessionServiceProvider);
    repo.pendingSave!.complete(true);
    await saving;
    expect(container.read(noteSessionServiceProvider), same(reloaded));
  });
}

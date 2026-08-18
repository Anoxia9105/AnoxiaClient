import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/provider/core/note_repository_provider.dart';
import 'package:anoxia/framework/provider/note/note_tree_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'note_trash_provider.g.dart';

/// 回收站服务
///
/// 管理回收站列表，提供还原 / 彻底删除 / 清空操作；
/// 还原或删除后自动刷新树与回收站列表。
@Riverpod(keepAlive: true)
class NoteTrashService extends _$NoteTrashService {
  @override
  FutureOr<List<NoteBrief>> build() {
    return ref.read(noteRepositoryProvider).getTrash();
  }

  /// 刷新回收站列表
  Future<void> refresh() async {
    final result =
        await AsyncValue.guard(() => ref.read(noteRepositoryProvider).getTrash());
    if (!ref.mounted) return;
    state = result;
  }

  /// 还原笔记
  Future<void> restore(int noteId) async {
    await ref.read(noteRepositoryProvider).restoreNote(noteId);
    await _afterMutation();
  }

  /// 彻底删除单篇笔记
  Future<void> purge(int noteId) async {
    await ref.read(noteRepositoryProvider).purgeNote(noteId);
    await _afterMutation();
  }

  /// 清空回收站
  Future<int> purgeAll() async {
    final count = await ref.read(noteRepositoryProvider).purgeAllTrash();
    await _afterMutation();
    return count;
  }

  Future<void> _afterMutation() async {
    await Future.wait([
      refresh(),
      ref.read(noteTreeServiceProvider.notifier).refresh(quiet: true),
    ]);
  }
}

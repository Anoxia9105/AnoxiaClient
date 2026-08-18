import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/provider/core/note_repository_provider.dart';
import 'package:anoxia/framework/provider/note/note_content_provider.dart';
import 'package:anoxia/framework/provider/note/note_tree_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'note_version_provider.g.dart';

/// 记事本版本历史服务
///
/// 版本列表每次从服务端拉取；还原成功后刷新树，若还原的是当前
/// 编辑中的笔记则重载会话内容。
@Riverpod(keepAlive: true)
class NoteVersionService extends _$NoteVersionService {
  @override
  FutureOr<List<NoteDocVersion>> build() {
    return const [];
  }

  /// 拉取指定笔记的版本列表
  Future<void> load(int noteId) async {
    final result = await AsyncValue.guard(
      () => ref.read(noteRepositoryProvider).getVersions(noteId),
    );
    if (!ref.mounted) return;
    state = result;
  }

  /// 还原到指定版本，刷新树并在必要时重载当前会话
  Future<bool> restore(int noteId, int version) async {
    final ok = await ref
        .read(noteRepositoryProvider)
        .restoreVersion(noteId, version);
    if (!ok) return false;
    if (!ref.mounted) return true;
    await ref.read(noteTreeServiceProvider.notifier).refresh(quiet: true);
    final session = ref.read(noteSessionServiceProvider);
    if (session?.noteId == noteId) {
      await ref.read(noteTreeServiceProvider.notifier).openNote(noteId);
    }
    await load(noteId);
    return true;
  }
}
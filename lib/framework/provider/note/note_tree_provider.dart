import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/domain/note_tree.dart';
import 'package:anoxia/framework/provider/core/note_repository_provider.dart';
import 'package:anoxia/framework/provider/note/note_content_provider.dart';
import 'package:anoxia/framework/provider/note/note_tag_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'note_tree_provider.g.dart';

/// 记事本完整树服务
///
/// 管理文件夹 / 笔记树，提供树查询与各类增删改、移动操作的封装，
/// 操作成功后自动刷新树。
@Riverpod(keepAlive: true)
class NoteTreeService extends _$NoteTreeService {
  /// 正在进行的树请求，防止并发重复拉取
  Future<NoteTree>? _fetchInflight;

  @override
  FutureOr<NoteTree> build() {
    return _fetchTree();
  }

  Future<NoteTree> _fetchTree() {
    return _fetchInflight ??= ref
        .read(noteRepositoryProvider)
        .getTree()
        .whenComplete(() => _fetchInflight = null);
  }

  /// 手动刷新树
  ///
  /// [quiet] 为 true 时静默刷新，不触发 loading 状态
  Future<void> refresh({bool quiet = false}) async {
    if (!quiet) {
      state = const AsyncValue.loading();
    }
    final result = await AsyncValue.guard(_fetchTree);
    if (!ref.mounted) return;
    state = result;
  }

  /// 创建文件夹
  ///
  /// 超过 [maxFolderDepth] 层时抛出 [NoteFolderDepthException]。
  Future<int> createFolder({int? parentId, required String name}) async {
    if (parentId != null && _isAtMaxDepth(parentId)) {
      throw const NoteFolderDepthException();
    }
    final id = await ref
        .read(noteRepositoryProvider)
        .createFolder(parentId: parentId, name: name);
    await refresh(quiet: true);
    return id;
  }

  /// 重命名文件夹
  Future<void> renameFolder(int folderId, String name) async {
    await ref.read(noteRepositoryProvider).renameFolder(folderId, name);
    await refresh(quiet: true);
  }

  /// 移动文件夹
  ///
  /// 移动后超过 [maxFolderDepth] 层时抛出 [NoteFolderDepthException]。
  Future<void> moveFolder(int folderId, int? targetParentId) async {
    if (_moveExceedsMaxDepth(folderId, targetParentId)) {
      throw const NoteFolderDepthException();
    }
    await ref.read(noteRepositoryProvider).moveFolder(folderId, targetParentId);
    await refresh(quiet: true);
  }

  /// 级联删除文件夹
  Future<NoteDeleteResult> deleteFolder(int folderId) async {
    final result = await ref
        .read(noteRepositoryProvider)
        .deleteFolder(folderId);
    await refresh(quiet: true);
    return result;
  }

  /// 新建笔记，返回全文
  Future<NoteDoc> createNote({int? folderId, String? title}) async {
    final doc = await ref
        .read(noteRepositoryProvider)
        .createNote(folderId: folderId, title: title);
    await refresh(quiet: true);
    return doc;
  }

  /// 移动笔记
  Future<void> moveNote(int noteId, int? targetFolderId) async {
    await ref.read(noteRepositoryProvider).moveNote(noteId, targetFolderId);
    await refresh(quiet: true);
  }

  /// 置顶 / 取消置顶笔记
  Future<void> setPinned(int noteId, {required bool pinned}) async {
    await ref.read(noteRepositoryProvider).setPinned(noteId, pinned: pinned);
    await refresh(quiet: true);
  }

  /// 批量移动并重排笔记
  Future<void> sortNotes(List<int> noteIds, int? targetFolderId) async {
    await ref.read(noteRepositoryProvider).sortNotes(noteIds, targetFolderId);
    await refresh(quiet: true);
  }

  /// 批量移动并重排文件夹
  ///
  /// 任一文件夹移动后超过 [maxFolderDepth] 层时抛出 [NoteFolderDepthException]。
  Future<void> sortFolders(List<int> folderIds, int? targetParentId) async {
    for (final id in folderIds) {
      if (_moveExceedsMaxDepth(id, targetParentId)) {
        throw const NoteFolderDepthException();
      }
    }
    await ref
        .read(noteRepositoryProvider)
        .sortFolders(folderIds, targetParentId);
    await refresh(quiet: true);
  }

  /// 打开笔记：拉取全文并启动编辑会话
  Future<NoteDoc> openNote(int noteId) async {
    final doc = await ref.read(noteRepositoryProvider).getNote(noteId);
    ref.read(noteSessionServiceProvider.notifier).open(doc);
    return doc;
  }

  /// 删除笔记
  Future<void> deleteNote(int noteId) async {
    await ref.read(noteRepositoryProvider).deleteNote(noteId);
    await refresh(quiet: true);
  }

  /// 整体替换笔记标签（find-or-create）
  Future<void> setTags(int noteId, List<String> tags) async {
    await ref.read(noteRepositoryProvider).replaceTags(noteId, tags);
    await refresh(quiet: true);
    if (ref.mounted) {
      await ref.read(noteTagServiceProvider.notifier).refresh();
    }
  }

  /// 删除标签（解除全部笔记关联）
  Future<void> deleteTag(int tagId) async {
    await ref.read(noteRepositoryProvider).deleteTag(tagId);
    await refresh(quiet: true);
    if (ref.mounted) {
      await ref.read(noteTagServiceProvider.notifier).refresh();
    }
  }

  /// 文件夹深度是否已达上限（无法再在其下新建/移入子文件夹）
  bool _isAtMaxDepth(int folderId) {
    final tree = state.value;
    if (tree == null) return false;
    return tree.isFolderAtMaxDepth(folderId);
  }

  /// 移动 [folderId] 到 [targetParentId] 后是否超出深度上限
  bool _moveExceedsMaxDepth(int folderId, int? targetParentId) {
    final tree = state.value;
    if (tree == null) return true;
    return tree.moveExceedsMaxDepth(folderId, targetParentId);
  }
}

/// 文件夹层级超出上限（[maxFolderDepth] 层）时抛出
class NoteFolderDepthException implements Exception {
  const NoteFolderDepthException();
}

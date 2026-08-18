import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/domain/note_tree.dart';

/// 记事本仓库抽象接口
///
/// 定义文件夹 / 笔记相关的数据操作契约。
/// 数据层通过实现此接口提供具体实现，UI 层 Provider 仅依赖此接口。
abstract interface class NoteRepository {
  /// 获取完整树（文件夹 + 笔记摘要）
  Future<NoteTree> getTree();

  /// 创建文件夹，返回新文件夹ID
  Future<int> createFolder({int? parentId, required String name});

  /// 重命名文件夹
  Future<bool> renameFolder(int folderId, String name);

  /// 移动文件夹（[targetParentId] 为 null 表示移至根）
  Future<bool> moveFolder(int folderId, int? targetParentId);

  /// 级联删除文件夹（含子文件夹与笔记）
  Future<NoteDeleteResult> deleteFolder(int folderId);

  /// 新建笔记，返回全文
  Future<NoteDoc> createNote({int? folderId, String? title});

  /// 获取笔记全文
  Future<NoteDoc> getNote(int noteId);

  /// 保存笔记（title/content/plainText 全量覆盖）
  Future<bool> saveNote(
    int noteId, {
    String? title,
    String? content,
    String? plainText,
  });

  /// 移动笔记（[targetFolderId] 为 null 表示移至未分类根级）
  Future<bool> moveNote(int noteId, int? targetFolderId);

  /// 置顶 / 取消置顶笔记
  Future<bool> setPinned(int noteId, {required bool pinned});

  /// 批量移动并重排笔记（[targetFolderId] 为 null 表示根级；[noteIds] 顺序即新 sort_order）
  Future<bool> sortNotes(List<int> noteIds, int? targetFolderId);

  /// 批量移动并重排文件夹（[targetParentId] 为 null 表示根级；[folderIds] 顺序即新 sort_order）
  Future<bool> sortFolders(List<int> folderIds, int? targetParentId);

  /// 删除笔记
  Future<bool> deleteNote(int noteId);

  /// 回收站列表（按删除时间倒序）
  Future<List<NoteBrief>> getTrash();

  /// 还原回收站笔记（所属文件夹已删除则恢复到根级）
  Future<bool> restoreNote(int noteId);

  /// 物理删除单篇回收站笔记
  Future<bool> purgeNote(int noteId);

  /// 清空回收站，返回删除数量
  Future<int> purgeAllTrash();

  /// 搜索笔记（标题 / 纯文本）
  Future<List<NoteBrief>> search(String keyword);

  /// 版本历史列表（版本号倒序）
  Future<List<NoteDocVersion>> getVersions(int noteId);

  /// 还原到指定版本（服务端会先快照当前状态，还原可逆）
  Future<bool> restoreVersion(int noteId, int version);

  /// 标签列表（含关联笔记数）
  Future<List<NoteTag>> getTags();

  /// 整体替换笔记标签（find-or-create，[tags] 为 null/空则清空）
  Future<bool> replaceTags(int noteId, List<String> tags);

  /// 删除标签（解除全部笔记关联）
  Future<bool> deleteTag(int tagId);
}

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

  /// 删除笔记
  Future<bool> deleteNote(int noteId);

  /// 搜索笔记（标题 / 纯文本）
  Future<List<NoteBrief>> search(String keyword);
}

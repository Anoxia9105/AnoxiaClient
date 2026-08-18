import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/repositories/note_repository.dart';
import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/domain/note_tree.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/network/dio_client.dart';

/// 记事本仓库实现
///
/// 通过远程数据源（HTTP API）提供文件夹 / 笔记相关操作。
class NoteRepositoryImpl implements NoteRepository {
  @override
  Future<NoteTree> getTree() async {
    final response = await DioClient().get(API.noteTree);
    final data = _extractData(response);
    if (data is Map) {
      return NoteTree.fromJson(Map<String, dynamic>.from(data));
    }
    return const NoteTree(folders: [], rootNotes: []);
  }

  @override
  Future<int> createFolder({int? parentId, required String name}) async {
    final response = await DioClient().post(
      API.noteFolderBase,
      data: {'parentId': parentId, 'name': name},
    );
    final data = _extractData(response);
    return int.tryParse(data?.toString() ?? '') ?? 0;
  }

  @override
  Future<bool> renameFolder(int folderId, String name) async {
    return _isSuccess(
      await DioClient().put('${API.noteFolderBase}/$folderId', data: {'name': name}),
    );
  }

  @override
  Future<bool> moveFolder(int folderId, int? targetParentId) async {
    return _isSuccess(
      await DioClient().put(
        '${API.noteFolderBase}/$folderId/move',
        data: {'parentId': targetParentId},
      ),
    );
  }

  @override
  Future<NoteDeleteResult> deleteFolder(int folderId) async {
    final response = await DioClient().delete('${API.noteFolderBase}/$folderId');
    final data = _extractData(response);
    if (data is Map) {
      return NoteDeleteResult.fromJson(Map<String, dynamic>.from(data));
    }
    return const NoteDeleteResult(folderDeleted: 0, noteDeleted: 0);
  }

  @override
  Future<NoteDoc> createNote({int? folderId, String? title}) async {
    final response = await DioClient().post(
      API.noteBase,
      data: {'folderId': folderId, 'title': title ?? ''},
    );
    final data = _extractData(response);
    if (data is Map) {
      return NoteDoc.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('note_create_failed');
  }

  @override
  Future<NoteDoc> getNote(int noteId) async {
    final response = await DioClient().get('${API.noteBase}/$noteId');
    final data = _extractData(response);
    if (data is Map) {
      return NoteDoc.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('note_not_found');
  }

  @override
  Future<bool> saveNote(
    int noteId, {
    String? title,
    String? content,
    String? plainText,
  }) async {
    return _isSuccess(
      await DioClient().put(
        '${API.noteBase}/$noteId',
        data: {'title': title, 'content': content, 'plainText': plainText},
      ),
    );
  }

  @override
  Future<bool> moveNote(int noteId, int? targetFolderId) async {
    return _isSuccess(
      await DioClient().put(
        '${API.noteBase}/$noteId/move',
        data: {'folderId': targetFolderId},
      ),
    );
  }

  @override
  Future<bool> setPinned(int noteId, {required bool pinned}) async {
    return _isSuccess(
      await DioClient().put(
        '${API.noteBase}/$noteId/pin',
        data: {'pinned': pinned},
      ),
    );
  }

  @override
  Future<bool> sortNotes(List<int> noteIds, int? targetFolderId) async {
    return _isSuccess(
      await DioClient().put(
        '${API.noteBase}/sort',
        data: {'type': 'note', 'parentId': targetFolderId, 'ids': noteIds},
      ),
    );
  }

  @override
  Future<bool> sortFolders(List<int> folderIds, int? targetParentId) async {
    return _isSuccess(
      await DioClient().put(
        '${API.noteBase}/sort',
        data: {'type': 'folder', 'parentId': targetParentId, 'ids': folderIds},
      ),
    );
  }

  @override
  Future<bool> deleteNote(int noteId) async {
    return _isSuccess(await DioClient().delete('${API.noteBase}/$noteId'));
  }

  @override
  Future<List<NoteBrief>> getTrash() async {
    final response = await DioClient().get(API.noteTrash);
    final data = _extractData(response);
    if (data is List) {
      return data
          .map((e) => NoteBrief.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  @override
  Future<bool> restoreNote(int noteId) async {
    return _isSuccess(
      await DioClient().post('${API.noteTrash}/$noteId/restore'),
    );
  }

  @override
  Future<bool> purgeNote(int noteId) async {
    return _isSuccess(await DioClient().delete('${API.noteTrash}/$noteId'));
  }

  @override
  Future<int> purgeAllTrash() async {
    final response = await DioClient().delete(API.noteTrash);
    final data = _extractData(response);
    return int.tryParse(data?.toString() ?? '') ?? 0;
  }

  @override
  Future<List<NoteBrief>> search(String keyword) async {
    final response = await DioClient().get(
      API.noteSearch,
      queryParameters: {'q': keyword},
    );
    final data = _extractData(response);
    if (data is List) {
      return data
          .map((e) => NoteBrief.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  /// 兼容多种后端响应格式：`{code, data}` 中提取 data
  dynamic _extractData(dynamic response) {
    final data = response.data;
    if (data is! Map) return null;
    return data['data'];
  }

  bool _isSuccess(dynamic response) {
    try {
      final data = response.data;
      if (data is Map) {
        return data['code']?.toString() == '200';
      }
    } catch (e) {
      debugLog('记事本操作失败: $e');
    }
    return false;
  }
}

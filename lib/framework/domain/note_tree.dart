/// 记事本-文件夹树模型
///
/// [NoteFolderNode] 为树节点（含子文件夹与笔记），[NoteTree] 为根级视图。
library;

import 'package:flutter/foundation.dart';

import 'note_doc.dart';

/// 文件夹树节点
@immutable
class NoteFolderNode {
  final int id;

  /// 文件夹名称
  final String name;

  /// 同级排序
  final int sortOrder;

  /// 子文件夹
  final List<NoteFolderNode> children;

  /// 文件夹内笔记
  final List<NoteBrief> notes;

  const NoteFolderNode({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.children,
    required this.notes,
  });

  factory NoteFolderNode.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    final rawNotes = json['notes'];
    return NoteFolderNode(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      sortOrder: int.tryParse(
            json['sortOrder']?.toString() ?? json['sort_order']?.toString() ?? '',
          ) ??
          0,
      children: rawChildren is List
          ? rawChildren
              .map((e) => NoteFolderNode.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      notes: rawNotes is List
          ? rawNotes.map((e) => NoteBrief.fromJson(Map<String, dynamic>.from(e))).toList()
          : const [],
    );
  }

  /// 递归统计该文件夹下（含子文件夹）的笔记总数
  int get totalNoteCount {
    var count = notes.length;
    for (final child in children) {
      count += child.totalNoteCount;
    }
    return count;
  }

  /// 递归查找指定文件夹节点
  NoteFolderNode? findFolder(int id) {
    if (this.id == id) return this;
    for (final child in children) {
      final result = child.findFolder(id);
      if (result != null) return result;
    }
    return null;
  }

  NoteFolderNode copyWith({
    int? id,
    String? name,
    int? sortOrder,
    List<NoteFolderNode>? children,
    List<NoteBrief>? notes,
  }) {
    return NoteFolderNode(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      children: children ?? this.children,
      notes: notes ?? this.notes,
    );
  }
}

/// 记事本完整树
@immutable
class NoteTree {
  /// 根文件夹列表
  final List<NoteFolderNode> folders;

  /// 未分类（根级）笔记
  final List<NoteBrief> rootNotes;

  const NoteTree({required this.folders, required this.rootNotes});

  factory NoteTree.fromJson(Map<String, dynamic> json) {
    final rawFolders = json['folders'];
    final rawRootNotes = json['rootNotes'] ?? json['root_notes'];
    return NoteTree(
      folders: rawFolders is List
          ? rawFolders
              .map((e) => NoteFolderNode.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      rootNotes: rawRootNotes is List
          ? rawRootNotes.map((e) => NoteBrief.fromJson(Map<String, dynamic>.from(e))).toList()
          : const [],
    );
  }

  bool get isEmpty => folders.isEmpty && rootNotes.isEmpty;

  /// 全局笔记总数
  int get totalNoteCount {
    var count = rootNotes.length;
    for (final folder in folders) {
      count += folder.totalNoteCount;
    }
    return count;
  }

  /// 查找笔记（遍历所有文件夹与根级）
  NoteBrief? findNote(int id) {
    NoteBrief? searchInFolder(NoteFolderNode node) {
      for (final note in node.notes) {
        if (note.id == id) return note;
      }
      for (final child in node.children) {
        final result = searchInFolder(child);
        if (result != null) return result;
      }
      return null;
    }

    for (final folder in folders) {
      final result = searchInFolder(folder);
      if (result != null) return result;
    }
    for (final note in rootNotes) {
      if (note.id == id) return note;
    }
    return null;
  }

  /// 查找文件夹节点（含根级）
  NoteFolderNode? findFolder(int id) {
    for (final folder in folders) {
      final result = folder.findFolder(id);
      if (result != null) return result;
    }
    return null;
  }
}

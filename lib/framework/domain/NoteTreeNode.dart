import 'package:anoxia/framework/provider/note/model/note_entity.dart';

class NoteTreeNode {
  final int id;
  String name;
  final String type; // 'folder' | 'note'
  final int? parentId;
  String content;
  final String createdAt;
  String updatedAt;
  final int level;
  int sort;
  final List<NoteTreeNode> children;
  NoteTreeNode? parent;

  NoteTreeNode({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    this.content = '',
    required this.createdAt,
    required this.updatedAt,
    required this.level,
    this.sort = 0,
    List<NoteTreeNode>? children,
    this.parent,
  }) : children = children ?? [];

  factory NoteTreeNode.fromEntity(NoteEntity e) => NoteTreeNode(
    id: e.id,
    name: e.name,
    type: e.type,
    parentId: e.parentId,
    content: e.content,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
    level: e.level,
    sort: e.sort,
  );

  NoteEntity toEntity() => NoteEntity(
    id: id,
    name: name,
    type: type,
    parentId: parentId,
    content: content,
    createdAt: createdAt,
    updatedAt: updatedAt,
    level: level,
    sort: sort,
  );

  bool get isFolder => type == 'folder';
  bool get isNote => type == 'note';

  /// 扁平化所有子节点（BFS）
  List<NoteTreeNode> get allNotes {
    final result = <NoteTreeNode>[];
    _collectNotes(this, result);
    return result;
  }

  void _collectNotes(NoteTreeNode node, List<NoteTreeNode> result) {
    if (node.isNote) result.add(node);
    for (final child in node.children) {
      _collectNotes(child, result);
    }
  }
}

/// 从扁平列表构建树结构
List<NoteTreeNode> buildTree(List<NoteTreeNode> flat) {
  final map = <int, NoteTreeNode>{for (final n in flat) n.id: n};

  // 清空 children，防止重复
  for (final n in flat) {
    n.children.clear();
    n.parent = null;
  }

  final roots = <NoteTreeNode>[];
  for (final node in flat) {
    if (node.parentId == null) {
      roots.add(node);
    } else {
      final parent = map[node.parentId];
      if (parent != null) {
        node.parent = parent;
        parent.children.add(node);
      } else {
        roots.add(node); // 父节点不存在时作为根
      }
    }
  }

  // 按 sort 排序
  _sortChildren(roots);
  return roots;
}

void _sortChildren(List<NoteTreeNode> nodes) {
  nodes.sort((a, b) => a.sort.compareTo(b.sort));
  for (final n in nodes) {
    _sortChildren(n.children);
  }
}

/// 扁平化所有笔记（非文件夹）
List<NoteTreeNode> flattenNotes(List<NoteTreeNode> roots) {
  final result = <NoteTreeNode>[];
  void walk(List<NoteTreeNode> nodes) {
    for (final n in nodes) {
      if (n.isNote) result.add(n);
      walk(n.children);
    }
  }

  walk(roots);
  return result;
}

/// 扁平化所有节点
List<NoteTreeNode> flattenAll(List<NoteTreeNode> roots) {
  final result = <NoteTreeNode>[];
  void walk(List<NoteTreeNode> nodes) {
    for (final n in nodes) {
      result.add(n);
      walk(n.children);
    }
  }

  walk(roots);
  return result;
}

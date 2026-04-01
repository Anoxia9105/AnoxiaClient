import 'package:anoxia/framework/domain/NoteTreeNode.dart';
import 'package:anoxia/framework/provider/note/note_provider.dart';
import 'package:anoxia/pages/notes/RightClickTreeMenu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class LeftTreeView extends ConsumerStatefulWidget {
  const LeftTreeView({super.key});

  @override
  ConsumerState<LeftTreeView> createState() => _LeftTreeViewState();
}

class _LeftTreeViewState extends ConsumerState<LeftTreeView> {
  TreeController<NoteTreeNode>? _treeController;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  void _rebuildController(List<NoteTreeNode> roots) {
    _treeController?.dispose();
    _treeController = TreeController<NoteTreeNode>(
      roots: _filteredRoots(roots),
      childrenProvider: (node) => node.children,
      parentProvider: (node) => node.parent,
    );
    _treeController!.expandAll();
  }

  List<NoteTreeNode> _filteredRoots(List<NoteTreeNode> roots) {
    if (_searchQuery.isEmpty) return roots;
    return _filterNodes(roots, _searchQuery.toLowerCase());
  }

  List<NoteTreeNode> _filterNodes(List<NoteTreeNode> nodes, String q) {
    final result = <NoteTreeNode>[];
    for (final node in nodes) {
      final children = _filterNodes(node.children, q);
      if (node.name.toLowerCase().contains(q) || children.isNotEmpty) {
        result.add(node);
      }
    }
    return result;
  }

  bool _isDescendant(NoteTreeNode parent, NoteTreeNode potentialChild) {
    if (parent.id == potentialChild.id) return true;
    for (var child in parent.children) {
      if (_isDescendant(child, potentialChild)) return true;
    }
    return false;
  }

  Future<void> _showCreateDialog(
    BuildContext context, {
    required String type,
    NoteTreeNode? parent,
  }) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: Text(type == 'folder' ? '新建文件夹' : '新建笔记'),
          content: TextField(
            controller: c,
            autofocus: true,
            decoration: InputDecoration(
              hintText: type == 'folder' ? '文件夹名称' : '笔记名称',
            ),
            onSubmitted: (_) => Navigator.of(ctx).pop(c.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.indigo),
              ),
              onPressed: () => Navigator.of(ctx).pop(c.text),
              child: const Text('创建'),
            ),
          ],
        );
      },
    );

    if (name == null || name.trim().isEmpty) return;
    final notifier = ref.read(noteProvider.notifier);
    if (type == 'folder') {
      await notifier.createFolder(
        name: name.trim(),
        parentId: parent?.id,
        level: (parent?.level ?? -1) + 1,
      );
    } else {
      await notifier.createNote(
        name: name.trim(),
        parentId: parent?.id,
        level: (parent?.level ?? -1) + 1,
      );
    }
  }

  @override
  void dispose() {
    _treeController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noteProvider);
    final cs = Theme.of(context).colorScheme;

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('错误: $e')),
      data: (noteState) {
        final roots = noteState.roots;
        _rebuildController(roots);
        final tc = _treeController!;

        return Column(
          children: [
            // ── 搜索栏 ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '搜索笔记...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) {
                        setState(() => _searchQuery = v);
                        _rebuildController(roots);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.create_new_folder_outlined,
                      size: 18,
                    ),
                    tooltip: '新建文件夹',
                    onPressed: () => _showCreateDialog(context, type: 'folder'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.note_add_outlined, size: 18),
                    tooltip: '新建笔记',
                    onPressed: () => _showCreateDialog(context, type: 'note'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── 树形列表 ──────────────────────────────────────
            Expanded(
              child: roots.isEmpty
                  ? _EmptyTree(
                      onCreateNote: () =>
                          _showCreateDialog(context, type: 'note'),
                    )
                  : AnimatedTreeView<NoteTreeNode>(
                      treeController: tc,
                      nodeBuilder: (context, entry) {
                        return _TreeNodeTile(
                          entry: entry,
                          selectedId: noteState.selectedNode?.id,
                          roots: roots,
                          treeController: tc,
                          onTap: () {
                            if (entry.node.isNote) {
                              ref
                                  .read(noteProvider.notifier)
                                  .selectNode(entry.node);
                            } else {
                              tc.toggleExpansion(entry.node);
                            }
                          },
                          onNodeMoved: (node, newParent) {
                            ref
                                .read(noteProvider.notifier)
                                .moveNode(
                                  node.id,
                                  newParent?.id,
                                  (newParent?.level ?? -1) + 1,
                                );
                          },
                          onCreateChild: (type) => _showCreateDialog(
                            context,
                            type: type,
                            parent: entry.node,
                          ),
                          onDelete: (node) async {
                            final ok = await _confirmDelete(context, node.name);
                            if (ok == true) {
                              ref
                                  .read(noteProvider.notifier)
                                  .deleteNode(node.id);
                            }
                          },
                          onRename: (node) async {
                            final name = await _showRenameDialog(
                              context,
                              node.name,
                            );
                            if (name != null && name.trim().isNotEmpty) {
                              ref
                                  .read(noteProvider.notifier)
                                  .renameNode(node.id, name.trim());
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除「$name」？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRenameDialog(BuildContext context, String current) {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController(text: current);
        return AlertDialog(
          title: const Text('重命名'),
          content: TextField(
            controller: c,
            autofocus: true,
            onSubmitted: (_) => Navigator.of(ctx).pop(c.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.indigo),
              ),
              onPressed: () => Navigator.of(ctx).pop(c.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
}

// ── 单个节点 Tile ────────────────────────────────────────────
class _TreeNodeTile extends StatelessWidget {
  final TreeEntry<NoteTreeNode> entry;
  final int? selectedId;
  final List<NoteTreeNode> roots;
  final TreeController<NoteTreeNode> treeController;
  final VoidCallback onTap;
  final void Function(NoteTreeNode node, NoteTreeNode? newParent) onNodeMoved;
  final void Function(String type) onCreateChild;
  final void Function(NoteTreeNode) onDelete;
  final void Function(NoteTreeNode) onRename;

  const _TreeNodeTile({
    required this.entry,
    required this.selectedId,
    required this.roots,
    required this.treeController,
    required this.onTap,
    required this.onNodeMoved,
    required this.onCreateChild,
    required this.onDelete,
    required this.onRename,
  });

  bool _isDescendant(NoteTreeNode parent, NoteTreeNode child) {
    if (parent.id == child.id) return true;
    for (final c in parent.children) {
      if (_isDescendant(c, child)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final node = entry.node;
    final cs = Theme.of(context).colorScheme;
    final isSelected = node.id == selectedId && node.isNote;

    Widget tile = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primaryContainer.withValues(alpha: 0.6)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: node.isFolder
            ? Icon(
                entry.isExpanded ? Icons.folder_open : Icons.folder,
                size: 18,
                color: Colors.amber.shade600,
              )
            : HugeIcon(
                icon: HugeIcons.strokeRoundedNote01,
                size: 18,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
              ),
        title: Text(
          node.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? cs.primary : cs.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: node.isFolder && node.children.isNotEmpty
            ? Icon(
                entry.isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: cs.outline,
              )
            : null,
        onTap: onTap,
      ),
    );

    return TreeDragTarget<NoteTreeNode>(
      node: node,
      onNodeAccepted: (details) {
        final dragged = details.draggedNode as NoteTreeNode;
        final target = details.targetNode as NoteTreeNode;
        if (_isDescendant(dragged, target)) return;
        onNodeMoved(dragged, target.isFolder ? target : target.parent);
      },
      builder: (context, details) {
        if (details != null) {
          tile = DecoratedBox(
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: tile,
          );
        }
        return RightClickTreeMenu<NoteTreeNode>(
          node: node,
          roots: roots,
          controller: treeController,
          getTitle: (n) => n.name,
          createNode: null,
          addChild: (newNode, parent) {
            newNode.parent = parent;
            parent.children.add(newNode);
          },
          onDeleted: onDelete,
          child: TreeDraggable<NoteTreeNode>(
            node: node,
            feedback: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      node.isFolder ? Icons.folder : Icons.sticky_note_2,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(node.name, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
            child: TreeIndentation(entry: entry, child: tile),
          ),
        );
      },
    );
  }
}

class _EmptyTree extends StatelessWidget {
  final VoidCallback onCreateNote;

  const _EmptyTree({required this.onCreateNote});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 48, color: cs.outlineVariant),
          const SizedBox(height: 8),
          Text('还没有笔记', style: TextStyle(color: cs.outline)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onCreateNote,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('创建第一篇'),
          ),
        ],
      ),
    );
  }
}

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
        final noteCount = noteState.flatNotes.length;
        final folderCount = flattenAll(roots).where((e) => e.isFolder).length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.account_tree_rounded,
                            size: 18,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '笔记结构',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$noteCount 篇笔记 · $folderCount 个文件夹',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '搜索笔记、文件夹...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  _rebuildController(roots);
                                },
                                icon: const Icon(Icons.close_rounded, size: 16),
                              ),
                        filled: true,
                        fillColor: cs.surfaceContainerLow,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) {
                        setState(() => _searchQuery = v);
                        _rebuildController(roots);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionChipButton(
                            icon: Icons.note_add_outlined,
                            label: '新建笔记',
                            onTap: () => _showCreateDialog(context, type: 'note'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionChipButton(
                            icon: Icons.create_new_folder_outlined,
                            label: '新建文件夹',
                            onTap: () =>
                                _showCreateDialog(context, type: 'folder'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
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
                              onCreateChild: (target, type, name) async {
                                final parent = target.isFolder
                                    ? target
                                    : target.parent;
                                final notifier = ref.read(noteProvider.notifier);

                                if (type == 'folder') {
                                  await notifier.createFolder(
                                    name: name,
                                    parentId: parent?.id,
                                    level: (parent?.level ?? -1) + 1,
                                  );
                                } else {
                                  await notifier.createNote(
                                    name: name,
                                    parentId: parent?.id,
                                    level: (parent?.level ?? -1) + 1,
                                  );
                                }
                              },
                              onDelete: (node) async {
                                final ok = await _confirmDelete(
                                  context,
                                  node.name,
                                );
                                if (ok == true) {
                                  ref
                                      .read(noteProvider.notifier)
                                      .deleteNode(node.id);
                                }
                              },
                              onRename: (node, newName) async {
                                await ref
                                    .read(noteProvider.notifier)
                                    .renameNode(node.id, newName);
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
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
  final VoidCallback onTap;
  final void Function(NoteTreeNode node, NoteTreeNode? newParent) onNodeMoved;
  final Future<void> Function(NoteTreeNode node, String type, String name)
  onCreateChild;
  final void Function(NoteTreeNode) onDelete;
  final Future<void> Function(NoteTreeNode node, String newName) onRename;

  const _TreeNodeTile({
    required this.entry,
    required this.selectedId,
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primaryContainer.withValues(alpha: 0.72)
            : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        dense: true,
        minLeadingWidth: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: node.isFolder
            ? Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  entry.isExpanded ? Icons.folder_open_rounded : Icons.folder,
                  size: 18,
                  color: Colors.amber.shade800,
                ),
              )
            : Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.12)
                      : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedNote01,
                  size: 18,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
        title: Text(
          node.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? cs.primary : cs.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: node.isFolder
            ? Text(
                '${node.children.length} 个项目',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              )
            : null,
        trailing: node.isFolder && node.children.isNotEmpty
            ? Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  entry.isExpanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 16,
                  color: cs.outline,
                ),
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
          getTitle: (n) => n.name,
          onCreateChild: onCreateChild,
          onDeleted: onDelete,
          onRename: onRename,
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.note_alt_rounded, size: 34, color: cs.primary),
            ),
            const SizedBox(height: 14),
            Text(
              '还没有笔记',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '从第一篇笔记开始搭建你的知识树。',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onCreateNote,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('创建第一篇'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

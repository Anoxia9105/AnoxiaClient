import 'dart:async';

import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/domain/note_tree.dart';
import 'package:anoxia/framework/provider/core/note_repository_provider.dart';
import 'package:anoxia/framework/provider/note/note_tree_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../common/widgets/toast.dart';
import 'note_dialogs.dart';

/// 树节点操作
enum _NodeAction { newNote, newSubfolder, rename, move, delete }

/// 记事本树面板
///
/// 左侧树形结构：根级笔记 + 可展开文件夹。支持搜索（服务端）、
/// 新建笔记/文件夹、右键/长按菜单（新建子文件夹、重命名、移动、删除）。
class NoteTreePanel extends ConsumerStatefulWidget {
  /// 当前选中（已打开）的笔记 ID，用于高亮
  final int? selectedNoteId;

  /// 打开笔记回调（桌面选中 + 移动端 push 均由页面决定）
  final ValueChanged<NoteBrief> onOpenNote;

  const NoteTreePanel({
    super.key,
    required this.selectedNoteId,
    required this.onOpenNote,
  });

  @override
  ConsumerState<NoteTreePanel> createState() => _NoteTreePanelState();
}

class _NoteTreePanelState extends ConsumerState<NoteTreePanel> {
  final Set<int> _expanded = {};
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _query = '';
  List<NoteBrief>? _searchResults;
  bool _searching = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _query = '';
        _searchResults = null;
        _searching = false;
      });
      return;
    }
    setState(() {
      _query = query;
      _searching = true;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await ref
          .read(noteRepositoryProvider)
          .search(query)
          .catchError((_) => <NoteBrief>[]);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    });
  }

  Future<void> _createNote({int? folderId}) async {
    try {
      final doc = await ref
          .read(noteTreeServiceProvider.notifier)
          .createNote(folderId: folderId);
      if (!mounted) return;
      final brief = NoteBrief(
        id: doc.id,
        folderId: doc.folderId,
        title: doc.title,
        preview: doc.plainText,
        updatedAt: doc.updatedAt,
      );
      if (folderId != null) {
        setState(() => _expanded.add(folderId));
      }
      widget.onOpenNote(brief);
    } catch (e) {
      if (!mounted) return;
      Toast.showToast('note_create_failed'.tr(), type: ToastType.error);
    }
  }

  Future<void> _createFolder({int? parentId}) async {
    final name = await showNoteFolderNameDialog(
      context,
      title: 'note_new_folder'.tr(),
      confirmLabel: 'note_create'.tr(),
    );
    if (name == null || !mounted) return;
    try {
      await ref
          .read(noteTreeServiceProvider.notifier)
          .createFolder(parentId: parentId, name: name);
      if (parentId != null) {
        setState(() => _expanded.add(parentId));
      } else {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      Toast.showToast('note_folder_create_failed'.tr(), type: ToastType.error);
    }
  }

  Future<void> _renameFolder(NoteFolderNode folder) async {
    final name = await showNoteFolderNameDialog(
      context,
      title: 'note_rename'.tr(),
      confirmLabel: 'note_confirm'.tr(),
      initial: folder.name,
    );
    if (name == null || !mounted) return;
    try {
      await ref.read(noteTreeServiceProvider.notifier).renameFolder(
            folder.id,
            name,
          );
    } catch (e) {
      if (!mounted) return;
      Toast.showToast('note_rename_failed'.tr(), type: ToastType.error);
    }
  }

  Future<void> _moveFolder(NoteFolderNode folder) async {
    final tree = ref.read(noteTreeServiceProvider).value;
    if (tree == null || !mounted) return;
    final target = await showNoteMoveDialog(
      context,
      folders: tree.folders,
      title: 'note_move_to'.tr(),
      excludeId: folder.id,
    );
    if (target == null || !mounted) return;
    try {
      await ref
          .read(noteTreeServiceProvider.notifier)
          .moveFolder(folder.id, target.folderId);
    } catch (e) {
      if (!mounted) return;
      Toast.showToast('note_move_failed'.tr(), type: ToastType.error);
    }
  }

  Future<void> _deleteFolder(NoteFolderNode folder) async {
    final confirmed = await showNoteFolderDeleteDialog(
      context,
      folderName: folder.name,
      noteCount: folder.totalNoteCount,
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(noteTreeServiceProvider.notifier)
          .deleteFolder(folder.id);
      if (!mounted) return;
      Toast.showToast('note_delete_success'.tr(), type: ToastType.success);
    } catch (e) {
      if (!mounted) return;
      Toast.showToast('note_delete_failed'.tr(), type: ToastType.error);
    }
  }

  Future<void> _moveNote(NoteBrief note) async {
    final tree = ref.read(noteTreeServiceProvider).value;
    if (tree == null || !mounted) return;
    final target = await showNoteMoveDialog(
      context,
      folders: tree.folders,
      title: 'note_move_to'.tr(),
    );
    if (target == null || !mounted) return;
    try {
      await ref
          .read(noteTreeServiceProvider.notifier)
          .moveNote(note.id, target.folderId);
    } catch (e) {
      if (!mounted) return;
      Toast.showToast('note_move_failed'.tr(), type: ToastType.error);
    }
  }

  Future<void> _deleteNote(NoteBrief note) async {
    final confirmed = await showNoteDeleteDialog(context);
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(noteTreeServiceProvider.notifier).deleteNote(note.id);
      if (!mounted) return;
      Toast.showToast('note_delete_success'.tr(), type: ToastType.success);
    } catch (e) {
      if (!mounted) return;
      Toast.showToast('note_delete_failed'.tr(), type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final treeAsync = ref.watch(noteTreeServiceProvider);

    return Column(
      children: [
        _buildHeader(context, colorScheme, treeAsync),
        if (_query.isEmpty)
          _buildActionRow(context, colorScheme),
        const SizedBox(height: 6),
        _buildSearchField(context, colorScheme),
        const SizedBox(height: 6),
        Expanded(child: _buildBody(context, colorScheme, treeAsync)),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    AsyncValue<NoteTree> treeAsync,
  ) {
    final tree = treeAsync.value;
    final total = tree?.totalNoteCount ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: .6)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedNote01,
              color: colorScheme.primary,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'sidebar_note'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'note_total_count'.tr(args: [total.toString()]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'call_window_retry'.tr(),
            onPressed: () =>
                ref.read(noteTreeServiceProvider.notifier).refresh(),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh01,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: HugeIcons.strokeRoundedNote02,
              label: 'note_new'.tr(),
              onPressed: () => _createNote(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              icon: HugeIcons.strokeRoundedFolderAdd,
              label: 'note_new_folder'.tr(),
              onPressed: () => _createFolder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: _searchController,
        onChanged: _onQueryChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'note_search_hint'.tr(),
          hintStyle: TextStyle(
            fontSize: 12.5,
            color: colorScheme.onSurfaceVariant.withValues(alpha: .7),
          ),
          prefixIconConstraints: const BoxConstraints.tightFor(
            width: 34,
            height: 34,
          ),
          prefixIcon: Center(
            child: SizedBox.square(
              dimension: 15,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch02,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  tooltip: 'cancel'.tr(),
                  iconSize: 16,
                  onPressed: () {
                    _searchController.clear();
                    _onQueryChanged('');
                  },
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 9),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme colorScheme,
    AsyncValue<NoteTree> treeAsync,
  ) {
    if (_query.isNotEmpty) {
      return _buildSearchResults(context, colorScheme);
    }

    return treeAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              color: colorScheme.error,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text('chat_load_failed'.tr()),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: () =>
                  ref.read(noteTreeServiceProvider.notifier).refresh(),
              child: Text('call_window_retry'.tr()),
            ),
          ],
        ),
      ),
      data: (tree) {
        if (tree.isEmpty) {
          return _buildEmpty(context, colorScheme);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
          children: [
            for (final note in tree.rootNotes)
              _NoteRow(
                note: note,
                selected: note.id == widget.selectedNoteId,
                onTap: () => widget.onOpenNote(note),
                onMenuPosition: (position) =>
                    _showNoteMenu(context, position, note),
              ),
            for (final folder in tree.folders)
              _buildFolder(context, colorScheme, folder),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(BuildContext context, ColorScheme colorScheme) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    final results = _searchResults;
    if (results == null) {
      return const SizedBox.shrink();
    }
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedSearchRemove,
              size: 34,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              'note_search_no_result'.tr(),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
      children: [
        for (final note in results)
          _NoteRow(
            note: note,
            selected: note.id == widget.selectedNoteId,
            onTap: () => widget.onOpenNote(note),
            onMenuPosition: (position) =>
                _showNoteMenu(context, position, note),
          ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: .18),
                  colorScheme.primary.withValues(alpha: .05),
                ],
              ),
              border: Border.all(color: colorScheme.primary.withValues(alpha: .15)),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedNote01,
              size: 30,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'note_empty_title'.tr(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'note_empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolder(
    BuildContext context,
    ColorScheme colorScheme,
    NoteFolderNode folder,
  ) {
    final expanded = _expanded.contains(folder.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FolderRow(
          folder: folder,
          expanded: expanded,
          onTap: () => setState(() {
            if (expanded) {
              _expanded.remove(folder.id);
            } else {
              _expanded.add(folder.id);
            }
          }),
          onMenuPosition: (position) =>
              _showFolderMenu(context, position, folder),
        ),
        if (expanded) ...[
          for (final note in folder.notes)
            _NoteRow(
              note: note,
              indent: 1,
              selected: note.id == widget.selectedNoteId,
              onTap: () => widget.onOpenNote(note),
              onMenuPosition: (position) =>
                  _showNoteMenu(context, position, note),
            ),
          for (final child in folder.children)
            _buildFolder(context, colorScheme, child),
        ],
      ],
    );
  }

  void _showFolderMenu(
    BuildContext context,
    Offset position,
    NoteFolderNode folder,
  ) {
    final size = MediaQuery.sizeOf(context);
    final relative = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      size.width - position.dx,
      size.height - position.dy,
    );

    showMenu<_NodeAction>(
      context: context,
      position: relative,
      items: [
        _menuEntry(_NodeAction.newNote, HugeIcons.strokeRoundedNote02, 'note_new'.tr()),
        _menuEntry(_NodeAction.newSubfolder, HugeIcons.strokeRoundedFolderAdd, 'note_new_subfolder'.tr()),
        _menuEntry(_NodeAction.rename, HugeIcons.strokeRoundedEdit02, 'note_rename'.tr()),
        _menuEntry(_NodeAction.move, HugeIcons.strokeRoundedMove01, 'note_move'.tr()),
        _menuEntry(_NodeAction.delete, HugeIcons.strokeRoundedDelete02, 'note_delete'.tr()),
      ],
    ).then((action) {
      if (!mounted || action == null) return;
      switch (action) {
        case _NodeAction.newNote:
          _createNote(folderId: folder.id);
        case _NodeAction.newSubfolder:
          _createFolder(parentId: folder.id);
        case _NodeAction.rename:
          _renameFolder(folder);
        case _NodeAction.move:
          _moveFolder(folder);
        case _NodeAction.delete:
          _deleteFolder(folder);
      }
    });
  }

  void _showNoteMenu(
    BuildContext context,
    Offset position,
    NoteBrief note,
  ) {
    final size = MediaQuery.sizeOf(context);
    final relative = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      size.width - position.dx,
      size.height - position.dy,
    );

    showMenu<_NodeAction>(
      context: context,
      position: relative,
      items: [
        _menuEntry(_NodeAction.move, HugeIcons.strokeRoundedMove01, 'note_move'.tr()),
        _menuEntry(_NodeAction.delete, HugeIcons.strokeRoundedDelete02, 'note_delete'.tr()),
      ],
    ).then((action) {
      if (!mounted || action == null) return;
      switch (action) {
        case _NodeAction.move:
          _moveNote(note);
        case _NodeAction.delete:
          _deleteNote(note);
        default:
          break;
      }
    });
  }

  PopupMenuEntry<_NodeAction> _menuEntry(
    _NodeAction action,
    List<List<dynamic>> icon,
    String label,
  ) {
    return PopupMenuItem<_NodeAction>(
      value: action,
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

/// 操作按钮（新建笔记 / 新建文件夹）
class _ActionButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                size: 15,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 文件夹行
class _FolderRow extends StatelessWidget {
  final NoteFolderNode folder;
  final bool expanded;
  final VoidCallback onTap;

  /// 右键 / 长按菜单回调，入参为全局坐标
  final ValueChanged<Offset> onMenuPosition;

  const _FolderRow({
    required this.folder,
    required this.expanded,
    required this.onTap,
    required this.onMenuPosition,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onSecondaryTapDown: (details) => onMenuPosition(details.globalPosition),
      onLongPressStart: (details) => onMenuPosition(details.globalPosition),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowDown01,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                HugeIcon(
                  icon: expanded
                      ? HugeIcons.strokeRoundedFolderOpen
                      : HugeIcons.strokeRoundedFolder01,
                  size: 17,
                  color: colorScheme.primary.withValues(alpha: .85),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (folder.totalNoteCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      folder.totalNoteCount.toString(),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 笔记行
class _NoteRow extends StatelessWidget {
  final NoteBrief note;
  final bool selected;
  final int indent;
  final VoidCallback onTap;

  /// 右键 / 长按菜单回调，入参为全局坐标
  final ValueChanged<Offset> onMenuPosition;

  const _NoteRow({
    required this.note,
    required this.selected,
    required this.onTap,
    required this.onMenuPosition,
    this.indent = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onSecondaryTapDown: (details) => onMenuPosition(details.globalPosition),
      onLongPressStart: (details) => onMenuPosition(details.globalPosition),
      child: Material(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: .35)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(8 + indent * 18, 8, 8, 8),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedFile02,
                  size: 15,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: .7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title.isEmpty
                            ? 'note_untitled'.tr()
                            : note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (note.preview.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          note.preview.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
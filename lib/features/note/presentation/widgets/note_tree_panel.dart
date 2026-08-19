import 'dart:async';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/domain/note_tree.dart';
import 'package:anoxia/framework/provider/core/note_repository_provider.dart';
import 'package:anoxia/framework/provider/note/note_tag_provider.dart';
import 'package:anoxia/framework/provider/note/note_tree_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../common/widgets/toast.dart';
import 'note_dialogs.dart';
import 'note_share.dart';
import 'note_tags_dialog.dart';
import 'note_tree_dnd.dart';
import 'note_trash_dialog.dart';

/// 树节点操作
enum _NodeAction {
  newNote,
  newSubfolder,
  rename,
  move,
  pin,
  tags,
  share,
  delete,
}

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

  /// 当前按标签过滤（null 表示不过滤）
  String? _activeTag;

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
        tags: doc.tags,
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
    } on NoteFolderDepthException {
      if (!mounted) return;
      Toast.showToast('note_folder_depth_limit'.tr(), type: ToastType.error);
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
      await ref
          .read(noteTreeServiceProvider.notifier)
          .renameFolder(folder.id, name);
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
      excludeSubtreeId: folder.id,
    );
    if (target == null || !mounted) return;
    try {
      await ref
          .read(noteTreeServiceProvider.notifier)
          .moveFolder(folder.id, target.folderId);
    } on NoteFolderDepthException {
      if (!mounted) return;
      Toast.showToast('note_folder_depth_limit'.tr(), type: ToastType.error);
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
      await ref.read(noteTreeServiceProvider.notifier).deleteFolder(folder.id);
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

  Future<void> _togglePinned(NoteBrief note) async {
    try {
      await ref
          .read(noteTreeServiceProvider.notifier)
          .setPinned(note.id, pinned: !note.pinned);
      if (!mounted) return;
      Toast.showToast(
        note.pinned ? 'note_unpin_success'.tr() : 'note_pin_success'.tr(),
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      Toast.showToast('note_pin_failed'.tr(), type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final treeAsync = ref.watch(noteTreeServiceProvider);

    return Column(
      children: [
        _buildHeader(context, colorScheme, treeAsync),
        if (_query.isEmpty) _buildActionRow(context, colorScheme),
        const SizedBox(height: 6),
        _buildSearchField(context, colorScheme),
        if (_query.isEmpty) ...[
          const SizedBox(height: 4),
          _buildTagFilterBar(context, colorScheme),
        ],
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
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: .6),
          ),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'note_trash'.tr(),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                onPressed: () => showNoteTrashDialog(context),
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                tooltip: 'call_window_retry'.tr(),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                onPressed: () =>
                    ref.read(noteTreeServiceProvider.notifier).refresh(),
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedRefresh01,
                  size: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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

  /// 标签过滤栏（点击标签按标签筛选笔记，可再次点击取消）
  Widget _buildTagFilterBar(BuildContext context, ColorScheme colorScheme) {
    final tagsAsync = ref.watch(noteTagServiceProvider);
    final tags = tagsAsync.value ?? const <NoteTag>[];

    if (tags.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _TagChip(
            label: 'note_tag_all'.tr(),
            selected: _activeTag == null,
            onTap: () => setState(() => _activeTag = null),
          ),
          for (final tag in tags) ...[
            const SizedBox(width: 6),
            _TagChip(
              label: '${tag.name} ${tag.count}',
              selected: _activeTag == tag.name,
              onTap: () => setState(() {
                _activeTag = _activeTag == tag.name ? null : tag.name;
              }),
            ),
          ],
        ],
      ),
    );
  }

  /// 按标签过滤的笔记列表（跨文件夹）
  Widget _buildTagFiltered(
    BuildContext context,
    ColorScheme colorScheme,
    NoteTree tree,
  ) {
    final tag = _activeTag;
    final notes = <NoteBrief>[];
    if (tag != null) {
      void collect(NoteFolderNode node) {
        for (final n in node.notes) {
          if (n.tags.contains(tag)) notes.add(n);
        }
        for (final child in node.children) {
          collect(child);
        }
      }

      for (final folder in tree.folders) {
        collect(folder);
      }
      for (final note in tree.rootNotes) {
        if (note.tags.contains(tag)) notes.add(note);
      }
    }

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedTag01,
              size: 34,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              'note_tag_no_note'.tr(),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
      children: [
        for (final note in notes)
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

  /// 编辑笔记标签
  Future<void> _editTags(NoteBrief note) async {
    await showNoteTagsDialog(context, noteId: note.id, initialTags: note.tags);
  }

  /// 分享笔记到聊天（拉取全文后以快照卡片发送）
  Future<void> _shareNote(NoteBrief note) async {
    try {
      final doc = await ref.read(noteRepositoryProvider).getNote(note.id);
      if (!mounted) return;
      await shareNoteToChat(
        context,
        ref,
        noteId: doc.id,
        title: doc.title,
        content: doc.plainText,
        preview: note.preview,
        updatedAt: doc.updatedAt?.millisecondsSinceEpoch.toString(),
      );
    } catch (_) {
      if (!mounted) return;
      Toast.showToast('note_share_failed'.tr(), type: ToastType.error);
    }
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme colorScheme,
    AsyncValue<NoteTree> treeAsync,
  ) {
    if (_query.isNotEmpty) {
      return _buildSearchResults(context, colorScheme);
    }
    if (_activeTag != null) {
      return treeAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Center(child: Text('chat_load_failed'.tr())),
        data: (tree) => _buildTagFiltered(context, colorScheme, tree),
      );
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
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                children: [
                  for (final note in tree.rootNotes)
                    _buildNoteRow(context, colorScheme, note, null),
                  for (final folder in tree.folders)
                    _buildFolder(context, colorScheme, folder, null, 0),
                ],
              ),
            ),
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
            highlight: _query,
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
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: .15),
              ),
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
    int? containerId,
    int depth,
  ) {
    final expanded = _expanded.contains(folder.id);
    final noteIndent = depth + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _wrapDnd(
          context: context,
          item: NoteDragItem(
            isFolder: true,
            id: folder.id,
            containerId: containerId,
          ),
          feedbackLabel: folder.name,
          targetContainerId: containerId,
          targetId: folder.id,
          targetIsFolder: true,
          child: _FolderRow(
            folder: folder,
            depth: depth,
            expanded: expanded,
            onTap: () => setState(() {
              if (expanded) {
                _expanded.remove(folder.id);
              } else {
                _expanded.add(folder.id);
              }
            }),
            onMenuPosition: (position) =>
                _showFolderMenu(context, position, folder, depth),
          ),
        ),
        if (expanded) ...[
          for (final note in folder.notes)
            _buildNoteRow(
              context,
              colorScheme,
              note,
              folder.id,
              indent: noteIndent,
            ),
          for (final child in folder.children)
            _buildFolder(context, colorScheme, child, folder.id, depth + 1),
        ],
      ],
    );
  }

  Widget _buildNoteRow(
    BuildContext context,
    ColorScheme colorScheme,
    NoteBrief note,
    int? containerId, {
    int indent = 0,
  }) {
    return _wrapDnd(
      context: context,
      item: NoteDragItem(
        isFolder: false,
        id: note.id,
        containerId: containerId,
      ),
      feedbackLabel: note.title.isEmpty ? 'note_untitled'.tr() : note.title,
      targetContainerId: containerId,
      targetId: note.id,
      targetIsFolder: false,
      child: _NoteRow(
        note: note,
        indent: indent,
        selected: note.id == widget.selectedNoteId,
        onTap: () => widget.onOpenNote(note),
        onMenuPosition: (position) => _showNoteMenu(context, position, note),
      ),
    );
  }

  /// 桌面端包一层拖拽（排序 / 移入文件夹）；移动端原样返回
  Widget _wrapDnd({
    required BuildContext context,
    required NoteDragItem item,
    required String feedbackLabel,
    required int? targetContainerId,
    required int targetId,
    required bool targetIsFolder,
    required Widget child,
  }) {
    if (!DeviceUtil.isDesktop(context)) return child;
    return NoteDraggableRow(
      item: item,
      feedbackLabel: feedbackLabel,
      child: child,
      canAccept: (dragged) => _canDropOnRow(
        dragged,
        containerId: targetContainerId,
        targetId: targetId,
        targetIsFolder: targetIsFolder,
      ),
      onDrop: (dragged) => _handleDrop(
        dragged,
        containerId: targetContainerId,
        targetId: targetId,
        targetIsFolder: targetIsFolder,
      ),
    );
  }

  /// 判断拖入目标行是否合法
  bool _canDropOnRow(
    NoteDragItem dragged, {
    required int? containerId,
    required int targetId,
    required bool targetIsFolder,
  }) {
    if (dragged.id == targetId) return false;
    final tree = ref.read(noteTreeServiceProvider).value;
    if (tree == null) return false;
    if (dragged.isFolder) {
      if (!targetIsFolder) return false;
      if (dragged.containerId == containerId) return true;
      // 移入文件夹：不能移入自身子孙，且移动后不能超过最大深度
      if (_isDescendant(tree, dragged.id, targetId)) return false;
      return !tree.moveExceedsMaxDepth(dragged.id, targetId);
    }
    if (targetIsFolder) return true; // 笔记 → 移入文件夹
    return dragged.containerId == containerId; // 笔记 → 同级重排
  }

  /// 处理拖放：同级重排或移入文件夹
  Future<void> _handleDrop(
    NoteDragItem dragged, {
    required int? containerId,
    required int targetId,
    required bool targetIsFolder,
  }) async {
    final tree = ref.read(noteTreeServiceProvider).value;
    if (tree == null) return;
    final notifier = ref.read(noteTreeServiceProvider.notifier);
    try {
      if (dragged.isFolder) {
        if (!targetIsFolder) return;
        if (dragged.containerId == containerId) {
          final ids = _reorderedIds(
            _containerIds(tree, containerId, folders: true),
            dragged.id,
            targetId,
          );
          await notifier.sortFolders(ids, containerId);
        } else {
          final target = tree.findFolder(targetId);
          if (target == null) return;
          final ids = [
            ...[for (final f in target.children) f.id],
            dragged.id,
          ];
          await notifier.sortFolders(ids, targetId);
        }
      } else {
        if (targetIsFolder) {
          final target = tree.findFolder(targetId);
          if (target == null) return;
          final ids = [
            ...[for (final n in target.notes) n.id],
            dragged.id,
          ];
          await notifier.sortNotes(ids, targetId);
        } else {
          final ids = _reorderedIds(
            _containerIds(tree, containerId, folders: false),
            dragged.id,
            targetId,
          );
          await notifier.sortNotes(ids, containerId);
        }
      }
    } on NoteFolderDepthException {
      if (!mounted) return;
      Toast.showToast('note_folder_depth_limit'.tr(), type: ToastType.error);
    } catch (e) {
      if (!mounted) return;
      Toast.showToast('note_move_failed'.tr(), type: ToastType.error);
    }
  }

  /// 容器内有序 ID 列表（笔记或文件夹，按展示顺序）
  List<int> _containerIds(
    NoteTree tree,
    int? containerId, {
    required bool folders,
  }) {
    if (containerId == null) {
      return folders
          ? [for (final f in tree.folders) f.id]
          : [for (final n in tree.rootNotes) n.id];
    }
    final folder = tree.findFolder(containerId);
    if (folder == null) return const [];
    return folders
        ? [for (final f in folder.children) f.id]
        : [for (final n in folder.notes) n.id];
  }

  /// 把 draggedId 移动到 targetId 的位置
  List<int> _reorderedIds(List<int> ids, int draggedId, int targetId) {
    final from = ids.indexOf(draggedId);
    final to = ids.indexOf(targetId);
    if (from < 0 || to < 0) return ids;
    final result = List<int>.of(ids);
    result.removeAt(from);
    result.insert(to, draggedId);
    return result;
  }

  /// descendantId 是否位于 ancestorId 的子树内
  bool _isDescendant(NoteTree tree, int ancestorId, int descendantId) {
    return tree.findFolder(ancestorId)?.findFolder(descendantId) != null;
  }

  /// 右键 / 长按菜单（圆角卡片、图标底、危险项红色、分组分隔线）
  Future<void> _showContextMenu(
    BuildContext context,
    Offset position, {
    required List<List<dynamic>> headerIcon,
    required String headerTitle,
    required List<_ContextMenuEntry> entries,
    required void Function(_NodeAction action) onSelected,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final relative = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      size.width - position.dx,
      size.height - position.dy,
    );

    final action = await showMenu<_NodeAction>(
      context: context,
      position: relative,
      color: colorScheme.surfaceContainerLow,
      elevation: 14,
      shadowColor: Colors.black.withValues(alpha: .3),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: .4),
        ),
      ),
      constraints: const BoxConstraints(minWidth: 224, maxWidth: 300),
      clipBehavior: Clip.antiAlias,
      items: [
        _ContextMenuHeaderEntry(icon: headerIcon, title: headerTitle),
        const PopupMenuDivider(height: 10),
        for (var i = 0; i < entries.length; i++) ...[
          if (entries[i].separatorBefore) const PopupMenuDivider(height: 10),
          _ContextMenuItem(entry: entries[i]),
        ],
      ],
    );

    if (!mounted || action == null) return;
    onSelected(action);
  }

  void _showFolderMenu(
    BuildContext context,
    Offset position,
    NoteFolderNode folder,
    int depth,
  ) {
    // depth 0 基（根级=0），对应 folderDepth 根级=1；深度到上限时禁止再建子文件夹
    final atMaxDepth = depth + 1 >= maxFolderDepth;
    _showContextMenu(
      context,
      position,
      headerIcon: HugeIcons.strokeRoundedFolder01,
      headerTitle: folder.name,
      entries: [
        _ContextMenuEntry(
          _NodeAction.newNote,
          HugeIcons.strokeRoundedNoteAdd,
          'note_new'.tr(),
        ),
        _ContextMenuEntry(
          _NodeAction.newSubfolder,
          HugeIcons.strokeRoundedFolderAdd,
          'note_new_subfolder'.tr(),
          enabled: !atMaxDepth,
        ),
        _ContextMenuEntry(
          _NodeAction.rename,
          HugeIcons.strokeRoundedEdit02,
          'note_rename'.tr(),
          separatorBefore: true,
        ),
        _ContextMenuEntry(
          _NodeAction.move,
          HugeIcons.strokeRoundedMove01,
          'note_move'.tr(),
        ),
        _ContextMenuEntry(
          _NodeAction.delete,
          HugeIcons.strokeRoundedDelete02,
          'note_delete'.tr(),
          danger: true,
          separatorBefore: true,
        ),
      ],
      onSelected: (action) {
        if (!mounted) return;
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
          default:
            break;
        }
      },
    );
  }

  void _showNoteMenu(BuildContext context, Offset position, NoteBrief note) {
    _showContextMenu(
      context,
      position,
      headerIcon: HugeIcons.strokeRoundedNote01,
      headerTitle: note.title.isEmpty ? 'note_untitled'.tr() : note.title,
      entries: [
        _ContextMenuEntry(
          _NodeAction.pin,
          note.pinned
              ? HugeIcons.strokeRoundedPinOff
              : HugeIcons.strokeRoundedPin02,
          note.pinned ? 'note_unpin'.tr() : 'note_pin'.tr(),
        ),
        _ContextMenuEntry(
          _NodeAction.tags,
          HugeIcons.strokeRoundedTag01,
          'note_tags'.tr(),
        ),
        _ContextMenuEntry(
          _NodeAction.share,
          HugeIcons.strokeRoundedShare01,
          'note_share'.tr(),
        ),
        _ContextMenuEntry(
          _NodeAction.move,
          HugeIcons.strokeRoundedMove01,
          'note_move'.tr(),
          separatorBefore: true,
        ),
        _ContextMenuEntry(
          _NodeAction.delete,
          HugeIcons.strokeRoundedDelete02,
          'note_delete'.tr(),
          danger: true,
          separatorBefore: true,
        ),
      ],
      onSelected: (action) {
        if (!mounted) return;
        switch (action) {
          case _NodeAction.pin:
            _togglePinned(note);
          case _NodeAction.tags:
            _editTags(note);
          case _NodeAction.share:
            _shareNote(note);
          case _NodeAction.move:
            _moveNote(note);
          case _NodeAction.delete:
            _deleteNote(note);
          default:
            break;
        }
      },
    );
  }
}

/// 右键菜单条目描述
class _ContextMenuEntry {
  const _ContextMenuEntry(
    this.action,
    this.icon,
    this.label, {
    this.danger = false,
    this.separatorBefore = false,
    this.enabled = true,
  });

  final _NodeAction action;
  final List<List<dynamic>> icon;
  final String label;

  /// 危险操作（删除）：图标与文字使用错误色
  final bool danger;

  /// 在条目上方插入分组分隔线
  final bool separatorBefore;

  /// 是否可点击（false 时置灰且不可触发）
  final bool enabled;
}

/// 右键菜单项：图标底 + 文字，带 hover 高亮
class _ContextMenuItem extends PopupMenuEntry<_NodeAction> {
  const _ContextMenuItem({required this.entry});

  final _ContextMenuEntry entry;

  @override
  double get height => 42;

  @override
  bool represents(_NodeAction? value) => value == entry.action;

  @override
  State<PopupMenuEntry<_NodeAction>> createState() => _ContextMenuItemState();
}

class _ContextMenuItemState extends State<_ContextMenuItem> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entry = widget.entry;
    final enabled = entry.enabled;
    final accent = entry.danger ? colorScheme.error : colorScheme.primary;
    final labelColor = !enabled
        ? colorScheme.onSurface.withValues(alpha: .35)
        : entry.danger
        ? colorScheme.error
        : colorScheme.onSurface;

    return InkWell(
      onTap: enabled
          ? () => Navigator.of(context).pop(widget.entry.action)
          : null,
      borderRadius: BorderRadius.circular(10),
      hoverColor: colorScheme.primaryContainer.withValues(alpha: .35),
      highlightColor: accent.withValues(alpha: .1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: enabled
                    ? accent.withValues(alpha: entry.danger ? .10 : .08)
                    : colorScheme.onSurface.withValues(alpha: .04),
                borderRadius: BorderRadius.circular(9),
              ),
              child: HugeIcon(
                icon: entry.icon,
                size: 16,
                color: !enabled
                    ? colorScheme.onSurface.withValues(alpha: .25)
                    : entry.danger
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 右键菜单顶部标题（显示文件夹 / 笔记名）
class _ContextMenuHeaderEntry extends PopupMenuEntry<_NodeAction> {
  const _ContextMenuHeaderEntry({required this.icon, required this.title});

  final List<List<dynamic>> icon;
  final String title;

  @override
  double get height => 44;

  @override
  bool represents(_NodeAction? value) => false;

  @override
  State<PopupMenuEntry<_NodeAction>> createState() =>
      _ContextMenuHeaderEntryState();
}

class _ContextMenuHeaderEntryState extends State<_ContextMenuHeaderEntry> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      color: colorScheme.primary.withValues(alpha: .05),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HugeIcon(
              icon: widget.icon,
              size: 14,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
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
              HugeIcon(icon: icon, size: 15, color: colorScheme.primary),
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

  /// 所在层级深度（根级为 0），用于缩进
  final int depth;

  /// 右键 / 长按菜单回调，入参为全局坐标
  final ValueChanged<Offset> onMenuPosition;

  const _FolderRow({
    required this.folder,
    required this.expanded,
    required this.onTap,
    required this.onMenuPosition,
    this.depth = 0,
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
            padding: EdgeInsets.fromLTRB(8 + depth * 18, 8, 8, 8),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
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

  /// 搜索高亮关键字（命中子串以高亮色渲染）
  final String? highlight;
  final VoidCallback onTap;

  /// 右键 / 长按菜单回调，入参为全局坐标
  final ValueChanged<Offset> onMenuPosition;

  const _NoteRow({
    required this.note,
    required this.selected,
    required this.onTap,
    required this.onMenuPosition,
    this.indent = 0,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = highlight?.trim() ?? '';

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
                      Row(
                        children: [
                          if (note.pinned) ...[
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedPin02,
                              size: 12,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: _buildHighlighted(
                              note.title.isEmpty
                                  ? 'note_untitled'.tr()
                                  : note.title,
                              query,
                              TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                              colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      if (note.preview.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        _buildHighlighted(
                          note.preview.trim(),
                          query,
                          TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          colorScheme.primary,
                        ),
                      ],
                      if (note.tags.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _buildTagChips(colorScheme),
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

  /// 标签小胶囊（最多展示 3 个，超出折叠为 +N）
  Widget _buildTagChips(ColorScheme colorScheme) {
    final tags = note.tags;
    final shown = tags.length > 3 ? tags.sublist(0, 3) : tags;
    final overflow = tags.length - shown.length;

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        for (final name in shown)
          _TagChip(label: name, selected: false, dense: true, onTap: null),
        if (overflow > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '+$overflow',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  /// 命中关键字高亮渲染（大小写不敏感）
  Widget _buildHighlighted(
    String text,
    String query,
    TextStyle style,
    Color highlightColor,
  ) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: _highlightSpans(text, query, style, highlightColor),
      ),
    );
  }

  List<TextSpan> _highlightSpans(
    String text,
    String query,
    TextStyle style,
    Color highlightColor,
  ) {
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    var start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: style));
        }
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: style.copyWith(
            color: highlightColor,
            fontWeight: FontWeight.w700,
            backgroundColor: highlightColor.withValues(alpha: .18),
          ),
        ),
      );
      start = index + query.length;
    }
    return spans;
  }
}

/// 标签胶囊（过滤栏 / 笔记行内标签）
class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;

  /// 紧凑模式（笔记行内标签，不可点击）
  final bool dense;
  final VoidCallback? onTap;

  const _TagChip({
    required this.label,
    required this.selected,
    this.dense = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: dense ? 18 : 24,
          padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 10),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: dense ? 10 : 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

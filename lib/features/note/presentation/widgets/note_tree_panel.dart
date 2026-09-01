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
import 'note_tree_panel_parts.dart';
import 'note_tree_widgets.dart';
import 'note_trash_dialog.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

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

  void _toggleExpand(int folderId) {
    setState(() {
      if (_expanded.contains(folderId)) {
        _expanded.remove(folderId);
      } else {
        _expanded.add(folderId);
      }
    });
  }

  void _showFolderMenu(
    BuildContext context,
    Offset position,
    NoteFolderNode folder,
    int depth,
  ) {
    NoteTreeContextMenu.showFolderMenu(
      context,
      position,
      folder,
      depth,
      onCreateNote: () => _createNote(folderId: folder.id),
      onCreateSubfolder: () => _createFolder(parentId: folder.id),
      onRename: () => _renameFolder(folder),
      onMove: () => _moveFolder(folder),
      onDelete: () => _deleteFolder(folder),
    );
  }

  void _showNoteMenu(BuildContext context, Offset position, NoteBrief note) {
    NoteTreeContextMenu.showNoteMenu(
      context,
      position,
      note,
      onPin: () => _togglePinned(note),
      onTags: () => _editTags(note),
      onShare: () => _shareNote(note),
      onMove: () => _moveNote(note),
      onDelete: () => _deleteNote(note),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final treeAsync = ref.watch(noteTreeServiceProvider);
    final total = treeAsync.value?.totalNoteCount ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: DeviceUtil.isMobile(context),
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'sidebar_note'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(RadiusToken.pill),
              ),
              child: Text(
                'note_total_count'.tr(args: [total.toString()]),
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'note_trash'.tr(),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(
              width: 34,
              height: 34,
            ),
            onPressed: () => showNoteTrashDialog(context),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              size: 17,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            tooltip: 'call_window_retry'.tr(),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(
              width: 34,
              height: 34,
            ),
            onPressed: () =>
                ref.read(noteTreeServiceProvider.notifier).refresh(),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh01,
              size: 17,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 标签过滤（标签）统一放在标题下面，随后是操作行与搜索框
          if (_query.isEmpty) ...[
            const NoteTreePanelTagFilterBar(),
            const SizedBox(height: 6),
          ],
          if (_query.isEmpty)
            NoteTreePanelActionRow(
              onCreateNote: () => _createNote(),
              onCreateFolder: () => _createFolder(),
            ),
          const SizedBox(height: 8),
          NoteTreePanelSearchField(
            controller: _searchController,
            query: _query,
            onChanged: _onQueryChanged,
            onClear: () {
              _searchController.clear();
              _onQueryChanged('');
            },
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(context, colorScheme, treeAsync)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme colorScheme,
    AsyncValue<NoteTree> treeAsync,
  ) {
    if (_query.isNotEmpty) {
      return NoteTreePanelSearchResultsView(
        searching: _searching,
        results: _searchResults,
        query: _query,
        selectedNoteId: widget.selectedNoteId,
        onOpenNote: widget.onOpenNote,
        onShowNoteMenu: _showNoteMenu,
      );
    }
    if (ref.watch(noteTagFilterProvider) != null) {
      return treeAsync.when(
        loading: () => const NoteTreeListSkeleton(),
        error: (e, _) => Center(child: Text('chat_load_failed'.tr())),
        data: (tree) => NoteTreePanelTagFilteredView(
          tree: tree,
          selectedNoteId: widget.selectedNoteId,
          onOpenNote: widget.onOpenNote,
          onShowNoteMenu: _showNoteMenu,
        ),
      );
    }

    return treeAsync.when(
      loading: () => const NoteTreeListSkeleton(),
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
          return const NoteTreePanelEmptyView();
        }
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                children: [
                  for (final note in tree.rootNotes)
                    NoteTreeNoteBranch(
                      note: note,
                      containerId: null,
                      selectedNoteId: widget.selectedNoteId,
                      onOpenNote: widget.onOpenNote,
                      onShowNoteMenu: _showNoteMenu,
                    ),
                  for (final folder in tree.folders)
                    NoteTreeFolderBranch(
                      folder: folder,
                      containerId: null,
                      depth: 0,
                      expandedIds: _expanded,
                      onToggleExpand: _toggleExpand,
                      selectedNoteId: widget.selectedNoteId,
                      onOpenNote: widget.onOpenNote,
                      onShowFolderMenu: _showFolderMenu,
                      onShowNoteMenu: _showNoteMenu,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

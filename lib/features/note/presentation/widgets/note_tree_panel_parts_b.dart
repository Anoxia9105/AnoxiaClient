import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/domain/note_tree.dart';
import 'package:anoxia/framework/provider/note/note_tree_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'note_tree_dnd.dart';
import 'note_tree_menu.dart';
import 'note_tree_widgets.dart';
/// 文件夹分支（递归构建文件夹及其子笔记/子文件夹）
class NoteTreeFolderBranch extends ConsumerWidget {
  final NoteFolderNode folder;
  final int? containerId;
  final int depth;
  final Set<int> expandedIds;
  final ValueChanged<int> onToggleExpand;
  final int? selectedNoteId;
  final ValueChanged<NoteBrief> onOpenNote;
  final void Function(BuildContext context, Offset position,
      NoteFolderNode folder, int depth) onShowFolderMenu;
  final void Function(BuildContext context, Offset position, NoteBrief note)
      onShowNoteMenu;

  const NoteTreeFolderBranch({
    super.key,
    required this.folder,
    required this.containerId,
    required this.depth,
    required this.expandedIds,
    required this.onToggleExpand,
    required this.selectedNoteId,
    required this.onOpenNote,
    required this.onShowFolderMenu,
    required this.onShowNoteMenu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = expandedIds.contains(folder.id);
    final noteIndent = depth + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NoteTreeDragWrap(
          item: NoteDragItem(
            isFolder: true,
            id: folder.id,
            containerId: containerId,
          ),
          feedbackLabel: folder.name,
          targetContainerId: containerId,
          targetId: folder.id,
          targetIsFolder: true,
          child: NoteTreeFolderRow(
            folder: folder,
            depth: depth,
            expanded: expanded,
            onTap: () => onToggleExpand(folder.id),
            onMenuPosition: (position) =>
                onShowFolderMenu(context, position, folder, depth),
          ),
        ),
        if (expanded) ...[
          for (final note in folder.notes)
            NoteTreeNoteBranch(
              note: note,
              containerId: folder.id,
              indent: noteIndent,
              selectedNoteId: selectedNoteId,
              onOpenNote: onOpenNote,
              onShowNoteMenu: onShowNoteMenu,
            ),
          for (final child in folder.children)
            NoteTreeFolderBranch(
              folder: child,
              containerId: folder.id,
              depth: depth + 1,
              expandedIds: expandedIds,
              onToggleExpand: onToggleExpand,
              selectedNoteId: selectedNoteId,
              onOpenNote: onOpenNote,
              onShowFolderMenu: onShowFolderMenu,
              onShowNoteMenu: onShowNoteMenu,
            ),
        ],
      ],
    );
  }
}

/// 笔记行（含拖拽包装）
class NoteTreeNoteBranch extends ConsumerWidget {
  final NoteBrief note;
  final int? containerId;
  final int indent;
  final int? selectedNoteId;
  final ValueChanged<NoteBrief> onOpenNote;
  final void Function(BuildContext context, Offset position, NoteBrief note)
      onShowNoteMenu;

  const NoteTreeNoteBranch({
    super.key,
    required this.note,
    required this.containerId,
    this.indent = 0,
    required this.selectedNoteId,
    required this.onOpenNote,
    required this.onShowNoteMenu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NoteTreeDragWrap(
      item: NoteDragItem(
        isFolder: false,
        id: note.id,
        containerId: containerId,
      ),
      feedbackLabel: note.title.isEmpty ? 'note_untitled'.tr() : note.title,
      targetContainerId: containerId,
      targetId: note.id,
      targetIsFolder: false,
      child: NoteTreeRow(
        note: note,
        indent: indent,
        selected: note.id == selectedNoteId,
        onTap: () => onOpenNote(note),
        onMenuPosition: (position) =>
            onShowNoteMenu(context, position, note),
      ),
    );
  }
}

/// 桌面端包一层拖拽（排序 / 移入文件夹）；移动端原样返回
class NoteTreeDragWrap extends ConsumerWidget {
  final NoteDragItem item;
  final String feedbackLabel;
  final int? targetContainerId;
  final int targetId;
  final bool targetIsFolder;
  final Widget child;

  const NoteTreeDragWrap({
    super.key,
    required this.item,
    required this.feedbackLabel,
    required this.targetContainerId,
    required this.targetId,
    required this.targetIsFolder,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!DeviceUtil.isDesktop(context)) return child;
    return NoteDraggableRow(
      item: item,
      feedbackLabel: feedbackLabel,
      canAccept: (dragged) => NoteTreeDndHelper.canDropOnRow(
        ref,
        dragged,
        containerId: targetContainerId,
        targetId: targetId,
        targetIsFolder: targetIsFolder,
      ),
      onDrop: (dragged) => NoteTreeDndHelper.handleDrop(
        ref,
        context,
        dragged,
        containerId: targetContainerId,
        targetId: targetId,
        targetIsFolder: targetIsFolder,
      ),
      child: child,
    );
  }
}

/// 拖拽判定与排序辅助
class NoteTreeDndHelper {
  /// 判断拖入目标行是否合法
  static bool canDropOnRow(
    WidgetRef ref,
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
  static Future<void> handleDrop(
    WidgetRef ref,
    BuildContext context,
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
      if (!context.mounted) return;
      Toast.showToast('note_folder_depth_limit'.tr(), type: ToastType.error);
    } catch (e) {
      if (!context.mounted) return;
      Toast.showToast('note_move_failed'.tr(), type: ToastType.error);
    }
  }

  /// 容器内有序 ID 列表（笔记或文件夹，按展示顺序）
  static List<int> _containerIds(
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
  static List<int> _reorderedIds(List<int> ids, int draggedId, int targetId) {
    final from = ids.indexOf(draggedId);
    final to = ids.indexOf(targetId);
    if (from < 0 || to < 0) return ids;
    final result = List<int>.of(ids);
    result.removeAt(from);
    result.insert(to, draggedId);
    return result;
  }

  /// descendantId 是否位于 ancestorId 的子树内
  static bool _isDescendant(NoteTree tree, int ancestorId, int descendantId) {
    return tree.findFolder(ancestorId)?.findFolder(descendantId) != null;
  }
}

// ---------------------------------------------------------------------------
// 右键 / 长按菜单辅助
// ---------------------------------------------------------------------------

/// 右键 / 长按菜单（圆角卡片、图标底、危险项红色、分组分隔线）辅助
class NoteTreeContextMenu {
  /// 通用菜单展示
  static Future<void> show(
    BuildContext context,
    Offset position, {
    required List<List<dynamic>> headerIcon,
    required String headerTitle,
    required List<NoteTreeMenuEntry> entries,
    required void Function(NoteTreeAction action) onSelected,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final relative = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      size.width - position.dx,
      size.height - position.dy,
    );

    final action = await showMenu<NoteTreeAction>(
      context: context,
      position: relative,
      color: colorScheme.surfaceContainerLow,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: .25),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: .4),
        ),
      ),
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
      clipBehavior: Clip.antiAlias,
      items: [
        NoteTreeMenuHeaderEntry(icon: headerIcon, title: headerTitle),
        const PopupMenuDivider(height: 6),
        for (var i = 0; i < entries.length; i++) ...[
          if (entries[i].separatorBefore) const PopupMenuDivider(height: 6),
          NoteTreeMenuItem(entry: entries[i]),
        ],
      ],
    );

    if (action == null || !context.mounted) return;
    onSelected(action);
  }

  /// 文件夹菜单
  static void showFolderMenu(
    BuildContext context,
    Offset position,
    NoteFolderNode folder,
    int depth, {
    required VoidCallback onCreateNote,
    required VoidCallback onCreateSubfolder,
    required VoidCallback onRename,
    required VoidCallback onMove,
    required VoidCallback onDelete,
  }) {
    // depth 0 基（根级=0），对应 folderDepth 根级=1；深度到上限时禁止再建子文件夹
    final atMaxDepth = depth + 1 >= maxFolderDepth;
    show(
      context,
      position,
      headerIcon: HugeIcons.strokeRoundedFolder01,
      headerTitle: folder.name,
      entries: [
        NoteTreeMenuEntry(
          NoteTreeAction.newNote,
          HugeIcons.strokeRoundedNoteAdd,
          'note_new'.tr(),
        ),
        NoteTreeMenuEntry(
          NoteTreeAction.newSubfolder,
          HugeIcons.strokeRoundedFolderAdd,
          'note_new_subfolder'.tr(),
          enabled: !atMaxDepth,
        ),
        NoteTreeMenuEntry(
          NoteTreeAction.rename,
          HugeIcons.strokeRoundedEdit02,
          'note_rename'.tr(),
          separatorBefore: true,
        ),
        NoteTreeMenuEntry(
          NoteTreeAction.move,
          HugeIcons.strokeRoundedMove01,
          'note_move'.tr(),
        ),
        NoteTreeMenuEntry(
          NoteTreeAction.delete,
          HugeIcons.strokeRoundedDelete02,
          'note_delete'.tr(),
          danger: true,
          separatorBefore: true,
        ),
      ],
      onSelected: (action) {
        switch (action) {
          case NoteTreeAction.newNote:
            onCreateNote();
          case NoteTreeAction.newSubfolder:
            onCreateSubfolder();
          case NoteTreeAction.rename:
            onRename();
          case NoteTreeAction.move:
            onMove();
          case NoteTreeAction.delete:
            onDelete();
          default:
            break;
        }
      },
    );
  }

  /// 笔记菜单
  static void showNoteMenu(
    BuildContext context,
    Offset position,
    NoteBrief note, {
    required VoidCallback onPin,
    required VoidCallback onTags,
    required VoidCallback onShare,
    required VoidCallback onMove,
    required VoidCallback onDelete,
  }) {
    show(
      context,
      position,
      headerIcon: HugeIcons.strokeRoundedNote01,
      headerTitle: note.title.isEmpty ? 'note_untitled'.tr() : note.title,
      entries: [
        NoteTreeMenuEntry(
          NoteTreeAction.pin,
          note.pinned
              ? HugeIcons.strokeRoundedPinOff
              : HugeIcons.strokeRoundedPin02,
          note.pinned ? 'note_unpin'.tr() : 'note_pin'.tr(),
        ),
        NoteTreeMenuEntry(
          NoteTreeAction.tags,
          HugeIcons.strokeRoundedTag01,
          'note_tags'.tr(),
        ),
        NoteTreeMenuEntry(
          NoteTreeAction.share,
          HugeIcons.strokeRoundedShare01,
          'note_share'.tr(),
        ),
        NoteTreeMenuEntry(
          NoteTreeAction.move,
          HugeIcons.strokeRoundedMove01,
          'note_move'.tr(),
          separatorBefore: true,
        ),
        NoteTreeMenuEntry(
          NoteTreeAction.delete,
          HugeIcons.strokeRoundedDelete02,
          'note_delete'.tr(),
          danger: true,
          separatorBefore: true,
        ),
      ],
      onSelected: (action) {
        switch (action) {
          case NoteTreeAction.pin:
            onPin();
          case NoteTreeAction.tags:
            onTags();
          case NoteTreeAction.share:
            onShare();
          case NoteTreeAction.move:
            onMove();
          case NoteTreeAction.delete:
            onDelete();
          default:
            break;
        }
      },
    );
  }
}

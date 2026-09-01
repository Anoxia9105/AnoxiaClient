import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/domain/note_tree.dart';
import 'package:anoxia/framework/provider/note/note_tag_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'note_tree_widgets.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

// ---------------------------------------------------------------------------
// 操作行 / 搜索框 / 标签过滤 / 空状态 / 搜索结果 / 标签过滤视图
// 从 note_tree_panel.dart 拆出，均为公开部件（super.key），保留中文注释与文案
// ---------------------------------------------------------------------------

/// 操作行（新建笔记 / 新建文件夹，图标按钮右对齐）
class NoteTreePanelActionRow extends StatelessWidget {
  final VoidCallback onCreateNote;
  final VoidCallback onCreateFolder;

  const NoteTreePanelActionRow({
    super.key,
    required this.onCreateNote,
    required this.onCreateFolder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'note_new'.tr(),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(
              width: 34,
              height: 34,
            ),
            onPressed: onCreateNote,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedNoteAdd,
              size: 17,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            tooltip: 'note_new_folder'.tr(),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(
              width: 34,
              height: 34,
            ),
            onPressed: onCreateFolder,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedFolderAdd,
              size: 17,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 搜索框
class NoteTreePanelSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const NoteTreePanelSearchField({
    super.key,
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'note_search_hint'.tr(),
          hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
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
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  tooltip: 'cancel'.tr(),
                  iconSize: 16,
                  onPressed: onClear,
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
}

/// 标签过滤条
class NoteTreePanelTagFilterBar extends ConsumerWidget {
  const NoteTreePanelTagFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(noteTagServiceProvider).value ?? const <NoteTag>[];
    final activeTag = ref.watch(noteTagFilterProvider);
    if (tags.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _TagChip(
            label: 'note_tag_all'.tr(),
            selected: activeTag == null,
            onTap: () =>
                ref.read(noteTagFilterProvider.notifier).state = null,
          ),
          for (final tag in tags) ...[
            const SizedBox(width: 6),
            _TagChip(
              label: '${tag.name} ${tag.count}',
              selected: activeTag == tag.name,
              onTap: () => ref.read(noteTagFilterProvider.notifier).state =
                  activeTag == tag.name ? null : tag.name,
            ),
          ],
        ],
      ),
    );
  }
}

/// 标签过滤视图（跨文件夹筛选含某标签的笔记）
class NoteTreePanelTagFilteredView extends ConsumerWidget {
  final NoteTree tree;
  final int? selectedNoteId;
  final ValueChanged<NoteBrief> onOpenNote;
  final void Function(BuildContext context, Offset position, NoteBrief note)
      onShowNoteMenu;

  const NoteTreePanelTagFilteredView({
    super.key,
    required this.tree,
    required this.selectedNoteId,
    required this.onOpenNote,
    required this.onShowNoteMenu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterTag = ref.watch(noteTagFilterProvider);
    if (filterTag == null) {
      return const SizedBox.shrink();
    }

    final matchingNotes = <NoteBrief>[];
    for (final folder in tree.folders) {
      _collectTaggedNotes(folder, filterTag, matchingNotes);
    }
    for (final note in tree.rootNotes) {
      if (note.tags.contains(filterTag)) {
        matchingNotes.add(note);
      }
    }

    if (matchingNotes.isEmpty) {
      return Center(
        child: Text(
          'note_tag_no_note'.tr(),
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: .6),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      itemCount: matchingNotes.length,
      itemBuilder: (context, index) {
        final note = matchingNotes[index];
        return NoteTreeRow(
          note: note,
          indent: 0,
          selected: note.id == selectedNoteId,
          onTap: () => onOpenNote(note),
          onMenuPosition: (position) =>
              onShowNoteMenu(context, position, note),
        );
      },
    );
  }

  void _collectTaggedNotes(
    NoteFolderNode folder,
    String filterTag,
    List<NoteBrief> result,
  ) {
    for (final note in folder.notes) {
      if (note.tags.contains(filterTag)) {
        result.add(note);
      }
    }
    for (final child in folder.children) {
      _collectTaggedNotes(child, filterTag, result);
    }
  }
}

/// 搜索结果视图
class NoteTreePanelSearchResultsView extends StatelessWidget {
  final bool searching;
  final List<NoteBrief>? results;
  final String query;
  final int? selectedNoteId;
  final ValueChanged<NoteBrief> onOpenNote;
  final void Function(BuildContext context, Offset position, NoteBrief note)
      onShowNoteMenu;

  const NoteTreePanelSearchResultsView({
    super.key,
    required this.searching,
    required this.results,
    required this.query,
    required this.selectedNoteId,
    required this.onOpenNote,
    required this.onShowNoteMenu,
  });

  @override
  Widget build(BuildContext context) {
    if (searching) return const NoteTreeListSkeleton();
    final searchResults = results;
    if (searchResults == null) return const SizedBox.shrink();
    if (searchResults.isEmpty) {
      return Center(
        child: Text(
          'note_search_no_result'.tr(),
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: .6),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final note = searchResults[index];
        return NoteTreeRow(
          note: note,
          indent: 0,
          highlight: query,
          selected: note.id == selectedNoteId,
          onTap: () => onOpenNote(note),
          onMenuPosition: (position) =>
              onShowNoteMenu(context, position, note),
        );
      },
    );
  }
}

/// 空状态
class NoteTreePanelEmptyView extends StatelessWidget {
  const NoteTreePanelEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
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
            child: SizedBox.square(
              dimension: 26,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedNote01,
                size: 26,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'note_empty_title'.tr(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'note_empty_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 内部辅助
// ---------------------------------------------------------------------------

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(RadiusToken.xl),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

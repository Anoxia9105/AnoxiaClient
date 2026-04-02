import 'package:anoxia/framework/provider/note/note_provider.dart';
import 'package:anoxia/pages/notes/LeftTreeView.dart';
import 'package:anoxia/pages/notes/widgets/NoteEditorWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_view/split_view.dart';

class TreeLayoutView extends ConsumerWidget {
  const TreeLayoutView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noteProvider).value;
    final selected = state?.selectedNode;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SplitView(
          viewMode: SplitViewMode.Horizontal,
          gripColor: cs.outlineVariant.withValues(alpha: 0.35),
          gripColorActive: cs.primary.withValues(alpha: 0.4),
          gripSize: 3,
          controller: SplitViewController(
            weights: [0.25, 0.75],
            limits: [WeightLimit(min: 0.18, max: 0.4), WeightLimit(min: 0.4)],
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                border: Border(
                  right: BorderSide(color: cs.outlineVariant, width: 0.6),
                ),
              ),
              child: const LeftTreeView(),
            ),
            Container(
              color: cs.surface,
              child: selected == null || selected.isFolder
                  ? _RightPlaceholder(isFolder: selected?.isFolder ?? false)
                  : NoteEditorWidget(key: ValueKey(selected.id), node: selected),
            ),
          ],
        ),
      ),
    );
  }
}

class _RightPlaceholder extends StatelessWidget {
  final bool isFolder;

  const _RightPlaceholder({this.isFolder = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 360,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer.withValues(alpha: 0.75),
              ),
              child: Icon(
                isFolder ? Icons.folder_open_rounded : Icons.edit_note_rounded,
                size: 40,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isFolder ? '选择文件夹中的笔记' : '从左侧选择一篇笔记开始编辑',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFolder ? '文件夹更适合整理结构，打开具体笔记后就能在这里继续写作。' : '选中任意一篇笔记后，右侧会立刻切换到沉浸式编辑区域。',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

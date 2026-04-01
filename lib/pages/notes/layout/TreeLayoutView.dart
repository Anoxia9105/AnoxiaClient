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

    return SplitView(
      viewMode: SplitViewMode.Horizontal,
      gripColor: cs.outlineVariant,
      gripColorActive: cs.primary.withValues(alpha: 0.4),
      gripSize: 1.5,
      controller: SplitViewController(
        weights: [0.25, 0.75],
        limits: [WeightLimit(min: 0.18, max: 0.4), WeightLimit(min: 0.4)],
      ),
      children: [
        // 左侧：树形导航
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(
              right: BorderSide(color: cs.outlineVariant, width: 0.5),
            ),
          ),
          child: const LeftTreeView(),
        ),

        // 右侧：编辑器
        selected == null || selected.isFolder
            ? _RightPlaceholder(isFolder: selected?.isFolder ?? false)
            : NoteEditorWidget(key: ValueKey(selected.id), node: selected),
      ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFolder ? Icons.folder_open : Icons.sticky_note_2_outlined,
            size: 64,
            color: cs.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            isFolder ? '选择文件夹中的笔记' : '从左侧选择一篇笔记开始编辑',
            style: TextStyle(color: cs.outline, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

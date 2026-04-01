import 'package:anoxia/framework/provider/note/note_provider.dart';
import 'package:anoxia/pages/notes/layout/CardLayoutView.dart';
import 'package:anoxia/pages/notes/layout/TreeLayoutView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noteProvider).value;
    final layoutMode = state?.layoutMode ?? NoteLayoutMode.card;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Icon(Icons.sticky_note_2, color: cs.primary, size: 22),
            const SizedBox(width: 8),
            const Text(
              '我的笔记',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // ── 布局切换 ──────────────────────────────────────
          _LayoutToggle(
            current: layoutMode,
            onChanged: (mode) {
              ref.read(noteProvider.notifier).setLayoutMode(mode);
            },
          ),
          const SizedBox(width: 4),
          // ── 新建笔记 ──────────────────────────────────────
          _CreateMenu(layoutMode: layoutMode),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outlineVariant),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: layoutMode == NoteLayoutMode.card
            ? const CardLayoutView(key: ValueKey('card'))
            : const TreeLayoutView(key: ValueKey('tree')),
      ),
    );
  }
}

// ── 布局切换按钮组 ────────────────────────────────────────────
class _LayoutToggle extends StatelessWidget {
  final NoteLayoutMode current;
  final void Function(NoteLayoutMode) onChanged;

  const _LayoutToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            icon: Icons.style_outlined,
            tooltip: '卡片视图',
            selected: current == NoteLayoutMode.card,
            onTap: () => onChanged(NoteLayoutMode.card),
          ),
          _ToggleBtn(
            icon: Icons.account_tree_outlined,
            tooltip: '树形视图',
            selected: current == NoteLayoutMode.tree,
            onTap: () => onChanged(NoteLayoutMode.tree),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── 新建按钮（带下拉）─────────────────────────────────────────
class _CreateMenu extends ConsumerWidget {
  final NoteLayoutMode layoutMode;

  const _CreateMenu({required this.layoutMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.note_add_outlined, size: 18),
          child: const Text('新建笔记'),
          onPressed: () => _createNote(context, ref),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.create_new_folder_outlined, size: 18),
          child: const Text('新建文件夹'),
          onPressed: () => _createFolder(context, ref),
        ),
      ],
      builder: (context, controller, child) => IconButton(
        onPressed: controller.isOpen ? controller.close : controller.open,
        icon: const Icon(Icons.add),
        tooltip: '新建',
      ),
    );
  }

  Future<void> _createNote(BuildContext context, WidgetRef ref) async {
    final name = await _inputDialog(context, '新建笔记', '笔记名称');
    if (name != null && name.trim().isNotEmpty) {
      ref.read(noteProvider.notifier).createNote(name: name.trim());
    }
  }

  Future<void> _createFolder(BuildContext context, WidgetRef ref) async {
    final name = await _inputDialog(context, '新建文件夹', '文件夹名称');
    if (name != null && name.trim().isNotEmpty) {
      ref.read(noteProvider.notifier).createFolder(name: name.trim());
    }
  }

  Future<String?> _inputDialog(
    BuildContext context,
    String title,
    String hint,
  ) {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: c,
            autofocus: true,
            decoration: InputDecoration(hintText: hint),
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
  }
}

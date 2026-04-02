import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:hugeicons/hugeicons.dart';

class RightClickTreeMenu<T extends Object> extends StatelessWidget {
  final T node;
  final Widget child;

  final String Function(T node)? getTitle;
  final Future<void> Function(T parent, String type, String name)? onCreateChild;
  final Future<void> Function(T node, String newName)? onRename;
  final void Function(T node)? onDeleted;

  const RightClickTreeMenu({
    super.key,
    required this.node,
    required this.child,
    this.getTitle,
    this.onCreateChild,
    this.onRename,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) async {
        final position = details.globalPosition;
        final result = await showMenu<String>(
          menuPadding: EdgeInsets.zero,
          elevation: 8,
          context: context,
          position: RelativeRect.fromLTRB(
            position.dx,
            position.dy,
            position.dx,
            position.dy,
          ),
          items: const [
            PopupMenuItem(
              value: 'addfolder',
              child: ListTile(
                dense: true,
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedFolderAdd,
                  size: 18,
                ),
                title: Text(
                  '添加文件夹',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            PopupMenuItem(
              value: 'add',
              child: ListTile(
                dense: true,
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedNoteAdd,
                  size: 18,
                ),
                title: Text(
                  '添加笔记',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                dense: true,
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete01,
                  size: 18,
                ),
                title: Text(
                  '删除',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            PopupMenuItem(
              value: 'rename',
              child: ListTile(
                dense: true,
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedEdit02,
                  size: 18,
                ),
                title: Text(
                  '重命名',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );

        if (result == 'add' || result == 'addfolder') {
          final title = await showDialog<String>(
            context: context,
            builder: (ctx) {
              final controller = TextEditingController();
              return AlertDialog(
                title: Text(result == 'add' ? '添加笔记' : '添加文件夹'),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: '请输入名称'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      '取消',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  FilledButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.indigo),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(controller.text),
                    child: const Text('添加'),
                  ),
                ],
              );
            },
          );

          if (title != null && title.trim().isNotEmpty) {
            await onCreateChild?.call(
              node,
              result == 'addfolder' ? 'folder' : 'note',
              title.trim(),
            );
          }
        } else if (result == 'rename') {
          final title = await showDialog<String>(
            context: context,
            builder: (ctx) {
              final controller = TextEditingController(
                text: getTitle?.call(node) ?? '',
              );
              return AlertDialog(
                title: const Text('重命名'),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: '请输入名称'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      '取消',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  FilledButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.indigo),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(controller.text),
                    child: const Text('保存'),
                  ),
                ],
              );
            },
          );

          if (title != null && title.trim().isNotEmpty) {
            await onRename?.call(node, title.trim());
          }
        } else if (result == 'delete') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('确认删除'),
              content: Text('是否要删除【${getTitle?.call(node) ?? '该节点'}】？'),
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

          if (confirmed == true) {
            onDeleted?.call(node);
          }
        }
      },
      child: child,
    );
  }
}

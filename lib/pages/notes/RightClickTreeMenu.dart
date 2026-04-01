import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:hugeicons/hugeicons.dart';

class RightClickTreeMenu<T extends Object> extends StatelessWidget {
  final T node;
  final List<T> roots;
  final TreeController<T> controller;
  final Widget child;

  final String Function(T node)? getTitle;
  final T Function()? createNode;
  final void Function(T newNode, T parent)? addChild;
  final void Function(T node)? onDeleted;

  const RightClickTreeMenu({
    super.key,
    required this.node,
    required this.roots,
    required this.controller,
    required this.child,
    this.getTitle,
    this.createNode,
    this.addChild,
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
            final newNode = createNode?.call();
            if (newNode != null) {
              (newNode as dynamic).title = title.trim(); // 假设节点有 title 属性
              addChild?.call(newNode, node);
              controller.rebuild();
            }
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
            if ((node as dynamic).parent != null) {
              (node as dynamic).parent.children.remove(node);
            } else {
              roots.remove(node);
            }
            onDeleted?.call(node);
            controller.rebuild();
          }
        }
      },
      child: child,
    );
  }
}

import 'package:anoxia/framework/domain/note_tree.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 移动目标：null 文件夹 ID 表示移至未分类根级
class NoteMoveTarget {
  final int? folderId;

  const NoteMoveTarget(this.folderId);
}

/// 新建 / 重命名文件夹输入对话框
Future<String?> showNoteFolderNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initial = '',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 30,
        decoration: InputDecoration(
          hintText: 'note_folder_name_hint'.tr(),
          isDense: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text('cancel'.tr()),
        ),
        FilledButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text('note_folder_name_empty'.tr())),
              );
              return;
            }
            Navigator.of(dialogContext).pop(name);
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// 移动文件夹 / 笔记目标选择对话框
///
/// 顶层提供「未分类」选项；文件夹按层级缩进展示。返回 null 表示取消。
/// [excludeId] 排除单个文件夹；[excludeSubtreeId] 排除该文件夹及其整个子树
/// （用于移动文件夹时避免移入自身或自身子孙形成循环）。
Future<NoteMoveTarget?> showNoteMoveDialog(
  BuildContext context, {
  required List<NoteFolderNode> folders,
  required String title,
  int? excludeId,
  int? excludeSubtreeId,
}) {
  return showDialog<NoteMoveTarget>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: SizedBox(
          width: 320,
          height: 320,
          child: ListView(
            children: [
              ListTile(
                leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedFolderOff,
                  size: 18,
                ),
                title: Text('note_uncategorized'.tr()),
                onTap: () =>
                    Navigator.of(dialogContext).pop(const NoteMoveTarget(null)),
              ),
              for (final folder in folders)
                ..._buildFolderOptions(
                  dialogContext,
                  folder,
                  0,
                  excludeId,
                  excludeSubtreeId,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      );
    },
  );
}

List<Widget> _buildFolderOptions(
  BuildContext context,
  NoteFolderNode folder,
  int depth,
  int? excludeId,
  int? excludeSubtreeId,
) {
  // 命中排除子树：自身与所有子孙都不展示
  if (folder.id == excludeSubtreeId) return const [];
  final widgets = <Widget>[];
  if (folder.id != excludeId) {
    widgets.add(
      ListTile(
        dense: true,
        leading: Padding(
          padding: EdgeInsets.only(left: (depth * 16).toDouble()),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedFolder01,
            size: 18,
          ),
        ),
        title: Text(folder.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () => Navigator.of(context).pop(NoteMoveTarget(folder.id)),
      ),
    );
  }
  for (final child in folder.children) {
    widgets.addAll(
      _buildFolderOptions(
        context,
        child,
        depth + 1,
        excludeId,
        excludeSubtreeId,
      ),
    );
  }
  return widgets;
}

/// 文件夹级联删除确认对话框
Future<bool?> showNoteFolderDeleteDialog(
  BuildContext context, {
  required String folderName,
  required int noteCount,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('note_folder_delete_confirm_title'.tr()),
      content: Text(
        'note_folder_delete_confirm_content'.tr(
          args: [folderName, noteCount.toString()],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('cancel'.tr()),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('note_delete'.tr()),
        ),
      ],
    ),
  );
}

/// 笔记删除确认对话框
Future<bool?> showNoteDeleteDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('note_delete_confirm_title'.tr()),
      content: Text('note_delete_confirm_content'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('cancel'.tr()),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('note_delete'.tr()),
        ),
      ],
    ),
  );
}

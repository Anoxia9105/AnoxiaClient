import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/provider/note/note_trash_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 打开回收站对话框
Future<void> showNoteTrashDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const NoteTrashDialog(),
  );
}

/// 回收站对话框
///
/// 展示已删除笔记（按删除时间倒序），支持还原 / 彻底删除 / 清空回收站。
class NoteTrashDialog extends ConsumerWidget {
  const NoteTrashDialog({super.key});

  Future<void> _restore(BuildContext context, WidgetRef ref, NoteBrief note) async {
    try {
      await ref.read(noteTrashServiceProvider.notifier).restore(note.id);
      if (!context.mounted) return;
      Toast.showToast('note_trash_restore_success'.tr(), type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      Toast.showToast('note_restore_failed'.tr(), type: ToastType.error);
    }
  }

  Future<void> _purge(BuildContext context, WidgetRef ref, NoteBrief note) async {
    final confirmed = await _confirm(
      context,
      title: 'note_trash_purge'.tr(),
      content: 'note_trash_purge_confirm'.tr(args: [_titleOf(note)]),
    );
    if (confirmed != true) return;
    try {
      await ref.read(noteTrashServiceProvider.notifier).purge(note.id);
      if (!context.mounted) return;
      Toast.showToast('note_trash_purge_success'.tr(), type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      Toast.showToast('note_purge_failed'.tr(), type: ToastType.error);
    }
  }

  Future<void> _purgeAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirm(
      context,
      title: 'note_trash_clear'.tr(),
      content: 'note_trash_clear_confirm'.tr(),
    );
    if (confirmed != true) return;
    try {
      final count = await ref.read(noteTrashServiceProvider.notifier).purgeAll();
      if (!context.mounted) return;
      Toast.showToast(
        'note_trash_clear_success'.tr(args: [count.toString()]),
        type: ToastType.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      Toast.showToast('note_trash_clear_failed'.tr(), type: ToastType.error);
    }
  }

  Future<bool?> _confirm(BuildContext context, {required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('note_confirm'.tr()),
          ),
        ],
      ),
    );
  }

  String _titleOf(NoteBrief note) {
    return note.title.trim().isEmpty ? 'note_untitled'.tr() : note.title.trim();
  }

  String _formatDeletedAt(DateTime? time) {
    if (time == null) return '';
    final local = time.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final trashAsync = ref.watch(noteTrashServiceProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'note_trash'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'note_trash_clear'.tr(),
                    onPressed: trashAsync.value?.isNotEmpty == true
                        ? () => _purgeAll(context, ref)
                        : null,
                    icon: HugeIcon(
icon: HugeIcons.strokeRoundedDelete02,
                    size: 18,
                    color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: trashAsync.when(
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => SizedBox(
                  height: 120,
                  child: Center(child: Text('chat_load_failed'.tr())),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return SizedBox(
                      height: 120,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedDelete02,
                              size: 30,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'note_trash_empty'.tr(),
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 12, endIndent: 12),
                    itemBuilder: (context, index) {
                      final note = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedFile02,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _titleOf(note),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDeletedAt(note.deletedAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => _restore(context, ref, note),
                              child: Text(
                                'note_trash_restore'.tr(),
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _purge(context, ref, note),
                              child: Text(
                                'note_trash_purge'.tr(),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('close'.tr()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

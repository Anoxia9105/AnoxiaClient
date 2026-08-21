import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/provider/note/note_version_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'note_dialog_skeleton.dart';

/// 打开版本历史对话框
Future<void> showNoteVersionsDialog(BuildContext context, int noteId) {
  return showEscClosableDialog<void>(
    context: context,
    builder: (_) => NoteVersionsDialog(noteId: noteId),
  );
}

/// 版本历史对话框
///
/// 展示笔记历史版本（版本号倒序），支持还原到任意版本；
/// 还原前服务端会先快照当前状态，因此还原可逆。
class NoteVersionsDialog extends ConsumerStatefulWidget {
  final int noteId;

  const NoteVersionsDialog({super.key, required this.noteId});

  @override
  ConsumerState<NoteVersionsDialog> createState() => _NoteVersionsDialogState();
}

class _NoteVersionsDialogState extends ConsumerState<NoteVersionsDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(noteVersionServiceProvider.notifier).load(widget.noteId);
    });
  }

  String _titleOf(NoteDocVersion v) {
    return v.title.trim().isEmpty ? 'note_untitled'.tr() : v.title.trim();
  }

  String _previewOf(NoteDocVersion v) {
    final text = v.preview.trim();
    if (text.isNotEmpty) return text;
    return _titleOf(v);
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final local = time.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _restore(NoteDocVersion version) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('note_version_restore'.tr()),
        content: Text(
          'note_version_restore_confirm'.tr(
            args: [version.version.toString(), _formatTime(version.createdAt)],
          ),
        ),
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
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(noteVersionServiceProvider.notifier)
          .restore(widget.noteId, version.version);
      if (!mounted) return;
      Toast.showToast('note_version_restored'.tr(), type: ToastType.success);
    } catch (e) {
      if (!mounted) return;
      Toast.showToast('note_version_restore_failed'.tr(), type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final versionsAsync = ref.watch(noteVersionServiceProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedTime01,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'note_versions'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: versionsAsync.when(
                loading: () => const NoteDialogListSkeleton(),
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
                              icon: HugeIcons.strokeRoundedTime01,
                              size: 30,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'note_versions_empty'.tr(),
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
                      final version = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(alpha: .5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#${version.version}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _titleOf(version),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _previewOf(version),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(version.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _restore(version),
                              child: Text(
                                'note_version_restore'.tr(),
                                style: const TextStyle(fontSize: 12.5),
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
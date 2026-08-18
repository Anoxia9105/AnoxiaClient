import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/provider/note/note_tree_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 打开编辑标签对话框
Future<void> showNoteTagsDialog(
  BuildContext context, {
  required int noteId,
  required List<String> initialTags,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => NoteTagsDialog(noteId: noteId, initialTags: initialTags),
  );
}

/// 编辑标签对话框
///
/// 展示当前标签（可逐个删除），输入框回车添加新标签，确认后整体替换保存。
class NoteTagsDialog extends ConsumerStatefulWidget {
  final int noteId;
  final List<String> initialTags;

  const NoteTagsDialog({super.key, required this.noteId, required this.initialTags});

  @override
  ConsumerState<NoteTagsDialog> createState() => _NoteTagsDialogState();
}

class _NoteTagsDialogState extends ConsumerState<NoteTagsDialog> {
  static const int _maxTags = 20;
  static const int _maxName = 64;

  late final List<String> _tags = [...widget.initialTags];
  final TextEditingController _input = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _addTag() {
    final name = _input.text.trim();
    if (name.isEmpty || name.length > _maxName) return;
    if (_tags.length >= _maxTags) return;
    if (_tags.contains(name)) {
      _input.clear();
      return;
    }
    setState(() => _tags.add(name));
    _input.clear();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(noteTreeServiceProvider.notifier)
          .setTags(widget.noteId, _tags);
      if (!mounted) return;
      Toast.showToast('note_tag_saved'.tr(), type: ToastType.success);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      Toast.showToast('note_tag_save_failed'.tr(), type: ToastType.error);
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedTag01,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'note_tags'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'note_tags_hint'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final name in _tags)
                      InputChip(
                        label: Text(name),
                        visualDensity: VisualDensity.compact,
                        onDeleted: () => setState(() => _tags.remove(name)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _input,
                onSubmitted: (_) => _addTag(),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'note_tag_add_hint'.tr(),
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: .7),
                  ),
                  prefixIconConstraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  prefixIcon: Center(
                    child: SizedBox.square(
                      dimension: 15,
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedTag01,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('cancel'.tr()),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text('note_confirm'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
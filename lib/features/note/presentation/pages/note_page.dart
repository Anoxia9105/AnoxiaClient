import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/provider/note/note_content_provider.dart';
import 'package:anoxia/framework/provider/note/note_tree_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/note_editor.dart';
import '../widgets/note_tree_panel.dart';

/// 记事本页面
///
/// - 桌面端：左侧树面板 + 右侧编辑器（主从布局）
/// - 移动端：树列表页，点击笔记 push 全屏编辑器
class NotesPage extends ConsumerStatefulWidget {
  /// 深链打开指定笔记（来自分享卡片等场景）
  final int? initialNoteId;

  const NotesPage({super.key, this.initialNoteId});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  int? _selectedNoteId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialNoteId;
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openNoteById(initial);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 当前打开的笔记被删除（或移出树）时，关闭会话并清除选中
    ref.listen(noteTreeServiceProvider, (previous, next) {
      final selected = _selectedNoteId;
      if (selected == null) return;
      final tree = next.value;
      if (tree != null && tree.findNote(selected) == null) {
        ref.read(noteSessionServiceProvider.notifier).close();
        if (mounted) setState(() => _selectedNoteId = null);
      }
    });

    final mobile = DeviceUtil.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: mobile
          ? AppBar(centerTitle: true, title: Text('sidebar_note'.tr()))
          : null,
      body: mobile
          ? NoteTreePanel(
              selectedNoteId: null,
              onOpenNote: _openNote,
            )
          : Row(
              children: [
                SizedBox(
                  width: 280,
                  child: NoteTreePanel(
                    selectedNoteId: _selectedNoteId,
                    onOpenNote: _openNote,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: NoteEditor()),
              ],
            ),
    );
  }

  Future<void> _openNote(NoteBrief brief) async {
    await _openNoteById(brief.id);
  }

  Future<void> _openNoteById(int noteId) async {
    // 切换前先把上一个会话的未保存内容落库，避免切换丢失
    await ref.read(noteSessionServiceProvider.notifier).save();
    if (!mounted) return;

    try {
      final doc = await ref
          .read(noteTreeServiceProvider.notifier)
          .openNote(noteId);
      if (!mounted) return;
      if (DeviceUtil.isMobile(context)) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const NoteEditorPage(),
          ),
        );
      } else {
        setState(() => _selectedNoteId = doc.id);
      }
    } catch (e) {
      if (!mounted) return;
      Toast.showToast('note_open_failed'.tr(), type: ToastType.error);
    }
  }
}

/// 移动端全屏笔记编辑器页
class NoteEditorPage extends ConsumerWidget {
  const NoteEditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('sidebar_note'.tr()),
      ),
      body: const NoteEditor(),
    );
  }
}
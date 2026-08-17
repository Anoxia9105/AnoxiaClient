import 'dart:async';
import 'dart:convert';

import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_style_config.dart';
import 'package:anoxia/framework/provider/note/note_content_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'note_quill_image_build.dart';
import 'note_toolbar.dart';

/// 记事本编辑器
///
/// 负责标题 + 富文本正文的编辑，1.5s 防抖自动保存到会话，状态条展示
/// 保存状态与字数统计。会话切换时通过 ValueKey(noteId) 重建内部编辑器。
class NoteEditor extends ConsumerWidget {
  const NoteEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(noteSessionServiceProvider);
    if (session == null) {
      return const _NoteEditorEmpty();
    }
    return NoteEditorBody(key: ValueKey(session.noteId), session: session);
  }
}

/// 单篇笔记编辑主体（按 noteId 区分实例）
class NoteEditorBody extends ConsumerStatefulWidget {
  final NoteEditSession session;

  const NoteEditorBody({super.key, required this.session});

  @override
  ConsumerState<NoteEditorBody> createState() => _NoteEditorBodyState();
}

class _NoteEditorBodyState extends ConsumerState<NoteEditorBody> {
  QuillController? _quillController;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _disposed = false;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _initEditor(widget.session);
  }

  @override
  void didUpdateWidget(covariant NoteEditorBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 会话切换（noteId 变化）时重建编辑器
    if (oldWidget.session.noteId != widget.session.noteId) {
      _teardownEditor();
      _initEditor(widget.session);
    }
  }

  void _initEditor(NoteEditSession session) {
    final delta = _tryDecodeDelta(session.content);
    _quillController = QuillController(
      document: delta,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _quillController!.addListener(_onQuillChanged);
    _wordCount = session.plainText.length;
  }

  Document _tryDecodeDelta(String content) {
    try {
      final json = jsonDecode(content);
      if (json is List) return Document.fromJson(json);
    } catch (_) {
      // 忽略损坏数据，回退到空文档
    }
    return Document();
  }

  void _teardownEditor() {
    _debounce?.cancel();
    _debounce = null;
    _quillController?.removeListener(_onQuillChanged);
    _quillController?.dispose();
    _quillController = null;
  }

  void _onQuillChanged() {
    final controller = _quillController;
    if (controller == null || _disposed) return;

    final delta = jsonEncode(controller.document.toDelta().toJson());
    final plain = controller.document.toPlainText();
    final notifier = ref.read(noteSessionServiceProvider.notifier);
    notifier.updateContent(content: delta, plainText: plain);

    final count = plain.length;
    if (count != _wordCount) {
      setState(() => _wordCount = count);
    }
    _scheduleSave();
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      if (_disposed || !mounted) return;
      ref.read(noteSessionServiceProvider.notifier).save();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _quillController?.removeListener(_onQuillChanged);
    _quillController?.dispose();
    _titleController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(noteSessionServiceProvider);
    final controller = _quillController;
    if (session == null || controller == null) {
      return const _NoteEditorEmpty();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      autofocus: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            HardwareKeyboard.instance.isControlPressed &&
            event.logicalKey == LogicalKeyboardKey.keyS) {
          ref.read(noteSessionServiceProvider.notifier).save();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _titleControllerOf(session),
              onChanged: (value) {
                ref.read(noteSessionServiceProvider.notifier).updateTitle(value);
                _scheduleSave();
              },
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'note_untitled'.tr(),
                hintStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 4),
          NoteToolbar(controller: controller, focusNode: _focusNode),
          Expanded(
            child: QuillEditor.basic(
              focusNode: _focusNode,
              controller: controller,
              config: QuillEditorConfig(
                enableSelectionToolbar: false,
                placeholder: 'note_content_placeholder'.tr(),
                autoFocus: false,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                customStyles: QuillStyleConfig.get(context),
                embedBuilders: [
                  NoteQuillImageBuild(),
                ],
              ),
            ),
          ),
          _buildStatusBar(context, session, colorScheme),
        ],
      ),
    );
  }

  /// 标题输入框控制器（延迟到真正需要时创建，避免重复创建泄漏）
  TextEditingController? _titleController;
  TextEditingController _titleControllerOf(NoteEditSession session) {
    return _titleController ??= TextEditingController(text: session.title);
  }

  Widget _buildStatusBar(
    BuildContext context,
    NoteEditSession session,
    ColorScheme colorScheme,
  ) {
    final saveLabel = switch (session.saveState) {
      NoteSaveState.saving => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            const SizedBox(width: 6),
            Text('note_autosave_saving'.tr()),
          ],
        ),
      NoteSaveState.saved => Text(
          'note_autosave_saved'.tr(
            args: [_formatTime(session.lastSavedAt)],
          ),
        ),
      NoteSaveState.failed => TextButton.icon(
          onPressed: () =>
              ref.read(noteSessionServiceProvider.notifier).save(),
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedRefresh01,
            size: 14,
          ),
          label: Text('note_autosave_failed'.tr()),
        ),
      NoteSaveState.idle => Text('note_autosave_idle'.tr()),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: .6),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: saveLabel),
          Text(
            'note_word_count'.tr(args: [_wordCount.toString()]),
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--:--';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

/// 未选中笔记时的空态
class _NoteEditorEmpty extends StatelessWidget {
  const _NoteEditorEmpty();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: .18),
                  colorScheme.primary.withValues(alpha: .05),
                ],
              ),
              border: Border.all(color: colorScheme.primary.withValues(alpha: .15)),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedNote01,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'note_editor_empty_title'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'note_editor_empty_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
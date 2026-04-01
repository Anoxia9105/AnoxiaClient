import 'dart:async';
import 'dart:convert';

import 'package:anoxia/framework/domain/NoteTreeNode.dart';
import 'package:anoxia/framework/provider/note/note_provider.dart';
import 'package:anoxia/pages/notes/QuillToolbarWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 单个笔记编辑器，带 5 秒自动保存
class NoteEditorWidget extends ConsumerStatefulWidget {
  final NoteTreeNode node;
  final bool showTitle;

  const NoteEditorWidget({
    super.key,
    required this.node,
    this.showTitle = true,
  });

  @override
  ConsumerState<NoteEditorWidget> createState() => _NoteEditorWidgetState();
}

class _NoteEditorWidgetState extends ConsumerState<NoteEditorWidget> {
  late QuillController _quillController;
  late TextEditingController _titleController;
  Timer? _saveTimer;
  bool _isDirty = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.node.name);
    _initQuill();
  }

  void _initQuill() {
    Document doc;
    try {
      if (widget.node.content.isNotEmpty) {
        doc = Document.fromJson(jsonDecode(widget.node.content) as List);
      } else {
        doc = Document();
      }
    } catch (_) {
      doc = Document();
    }

    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _quillController.addListener(_onContentChanged);
  }

  @override
  void didUpdateWidget(NoteEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id) {
      // 节点切换：先强制保存旧内容
      _forceSave();
      _quillController.removeListener(_onContentChanged);
      _quillController.dispose();
      _titleController.dispose();
      _titleController = TextEditingController(text: widget.node.name);
      _initQuill();
    }
  }

  void _onContentChanged() {
    if (!_isDirty) setState(() => _isDirty = true);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 5), _autoSave);
  }

  Future<void> _autoSave() async {
    if (!_isDirty || !mounted) return;
    await _doSave();
  }

  Future<void> _forceSave() async {
    _saveTimer?.cancel();
    if (_isDirty) await _doSave();
  }

  Future<void> _doSave() async {
    setState(() => _isSaving = true);
    final delta = jsonEncode(_quillController.document.toDelta().toJson());
    await ref.read(noteProvider.notifier).saveContent(widget.node.id, delta);
    if (mounted) {
      setState(() {
        _isDirty = false;
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _forceSave(); // 离开时保存
    _quillController.removeListener(_onContentChanged);
    _quillController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 标题区 ──────────────────────────────────────────
        if (widget.showTitle) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '无标题',
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        ref
                            .read(noteProvider.notifier)
                            .renameNode(widget.node.id, v.trim());
                      }
                    },
                  ),
                ),
                // 保存状态指示
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isSaving
                      ? const SizedBox(
                          key: ValueKey('saving'),
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      : _isDirty
                      ? Icon(
                          key: const ValueKey('dirty'),
                          Icons.circle,
                          size: 8,
                          color: cs.primary,
                        )
                      : Icon(
                          key: const ValueKey('saved'),
                          Icons.check_circle_outline,
                          size: 14,
                          color: Colors.green.shade400,
                        ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const Divider(height: 1),
        ],

        // ── 工具栏 ──────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
            ),
          ),
          child: MyQuillToolbar(controller: _quillController),
        ),

        // ── 编辑器 ──────────────────────────────────────────
        Expanded(
          child: QuillEditor(
            controller: _quillController,
            focusNode: FocusNode(),
            scrollController: ScrollController(),
            config: QuillEditorConfig(
              placeholder: '开始记录你的想法...',
              padding: const EdgeInsets.all(16),
              autoFocus: false,
            ),
          ),
        ),
      ],
    );
  }
}

/// 空状态占位
class NoteEmptyPlaceholder extends StatelessWidget {
  const NoteEmptyPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sticky_note_2_outlined,
            size: 64,
            color: cs.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text('没有笔记', style: TextStyle(color: cs.outline, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            '点击右上角 + 创建第一篇笔记',
            style: TextStyle(color: cs.outlineVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

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
  late final ScrollController _editorScrollController;

  Timer? _saveTimer;
  bool _isDirty = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editorScrollController = ScrollController();
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
    final delta = jsonEncode(_quillController.document.toDelta().toJson());
    await ref.read(noteProvider.notifier).saveContent(widget.node.id, delta);

    if (!mounted) return;
    setState(() {
      _isDirty = false;
      _isSaving = false;
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _forceSave();

    _quillController.removeListener(_onContentChanged);
    _quillController.dispose();
    _editorScrollController.dispose();
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
                          color: Colors.green,
                        ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const Divider(height: 1),
        ],

        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
            ),
          ),
          child: MyQuillToolbar(controller: _quillController),
        ),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LineNumberColumn(
                controller: _quillController,
                editorScrollController: _editorScrollController,
              ),
              Expanded(
                child: QuillEditor(
                  scrollController: _editorScrollController,
                  controller: _quillController,
                  focusNode: FocusNode(),
                  config: QuillEditorConfig(
                    placeholder: '开始记录你的想法...',
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoScrollBarBehavior extends ScrollBehavior {
  const _NoScrollBarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // 👈 不包 Scrollbar
  }
}

class _LineNumberColumn extends StatefulWidget {
  final QuillController controller;
  final ScrollController editorScrollController;

  const _LineNumberColumn({
    required this.controller,
    required this.editorScrollController,
  });

  @override
  State<_LineNumberColumn> createState() => _LineNumberColumnState();
}

class _LineNumberColumnState extends State<_LineNumberColumn> {
  static const double _lineHeight = 20.0;
  final ScrollController _lineScrollController = ScrollController();

  int lineCount = 1;

  @override
  void initState() {
    super.initState();
    _calcLines();

    widget.controller.addListener(_calcLines);
    widget.editorScrollController.addListener(_syncScroll);
  }

  String _normalizePlainText(String text) {
    // Quill 的 plainText 通常会多带一个结尾换行，去掉它，避免多出一行
    if (text.endsWith('\n')) {
      return text.substring(0, text.length - 1);
    }
    return text;
  }

  void _calcLines() {
    final text = _normalizePlainText(widget.controller.document.toPlainText());

    final lines = text.isEmpty ? 1 : text.split('\n').length;

    if (lines != lineCount) {
      setState(() => lineCount = lines);
    }
  }

  void _syncScroll() {
    if (!_lineScrollController.hasClients ||
        !widget.editorScrollController.hasClients) {
      return;
    }

    final editorPos = widget.editorScrollController.position;
    final linePos = _lineScrollController.position;

    final editorMax = editorPos.maxScrollExtent;
    final lineMax = linePos.maxScrollExtent;

    if (editorMax <= 0 || lineMax <= 0) {
      return;
    }

    // 按比例同步，而不是直接复制 offset
    final ratio = (editorPos.pixels / editorMax).clamp(0.0, 1.0);
    final target = (lineMax * ratio).clamp(0.0, lineMax);

    if ((linePos.pixels - target).abs() > 0.5) {
      _lineScrollController.jumpTo(target);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_calcLines);
    widget.editorScrollController.removeListener(_syncScroll);
    _lineScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ScrollConfiguration(
      behavior: const _NoScrollBarBehavior(),
      child: Container(
        width: 44,
        color: cs.surfaceContainerLowest,
        child: ListView.builder(
          controller: _lineScrollController,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 16, bottom: 16),
          itemExtent: _lineHeight,
          itemCount: lineCount,
          itemBuilder: (context, index) {
            return Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            );
          },
        ),
      ),
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

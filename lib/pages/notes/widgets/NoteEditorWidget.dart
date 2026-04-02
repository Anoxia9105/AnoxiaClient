import 'dart:async';
import 'dart:convert';

import 'package:anoxia/framework/domain/NoteTreeNode.dart';
import 'package:anoxia/framework/provider/note/note_provider.dart';
import 'package:anoxia/pages/notes/QuillToolbarWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final FocusNode _editorFocusNode;

  Timer? _saveTimer;
  bool _isDirty = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editorScrollController = ScrollController();
    _editorFocusNode = FocusNode();
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
    if (!mounted) return;
    setState(() => _isSaving = true);

    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.node.name) {
      await ref.read(noteProvider.notifier).renameNode(widget.node.id, newTitle);
    }

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
    _editorFocusNode.dispose();
    _titleController.dispose();

    super.dispose();
  }

  KeyEventResult _handleEditorKeyPress(KeyEvent event) {
    final isSaveShortcut =
        event is KeyDownEvent &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed) &&
        event.logicalKey == LogicalKeyboardKey.keyS;

    if (!isSaveShortcut) return KeyEventResult.ignored;

    _saveTimer?.cancel();
    _forceSave();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '正在编辑',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _titleController,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '无标题',
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (v) {
                            if (v.trim().isNotEmpty) {
                              ref
                                  .read(noteProvider.notifier)
                                  .renameNode(widget.node.id, v.trim());
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _SaveStatusBadge(isSaving: _isSaving, isDirty: _isDirty),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                '支持富文本编辑，内容会自动保存，也可以使用 Ctrl + S 手动保存。',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: MyQuillToolbar(controller: _quillController),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
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
                          focusNode: _editorFocusNode,
                          config: QuillEditorConfig(
                            placeholder: '开始记录你的想法...',
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                            onKeyPressed: (event, node) =>
                                _handleEditorKeyPress(event),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveStatusBadge extends StatelessWidget {
  final bool isSaving;
  final bool isDirty;

  const _SaveStatusBadge({required this.isSaving, required this.isDirty});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color backgroundColor;
    final Color foregroundColor;
    final Widget leading;
    final String label;

    if (isSaving) {
      backgroundColor = cs.primaryContainer;
      foregroundColor = cs.primary;
      leading = SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.8,
          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
        ),
      );
      label = '保存中';
    } else if (isDirty) {
      backgroundColor = cs.tertiaryContainer;
      foregroundColor = cs.onTertiaryContainer;
      leading = Icon(Icons.edit_rounded, size: 14, color: foregroundColor);
      label = '未保存';
    } else {
      backgroundColor = Colors.green.withValues(alpha: 0.12);
      foregroundColor = Colors.green.shade700;
      leading = Icon(Icons.check_rounded, size: 14, color: foregroundColor);
      label = '已保存';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
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

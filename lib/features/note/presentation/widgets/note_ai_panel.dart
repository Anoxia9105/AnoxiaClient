import 'dart:async';
import 'dart:convert';

import 'package:anoxia/framework/network/sse_client.dart';
import 'package:anoxia/framework/provider/core/toast_service_provider.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'note_ai_langs.dart';
import 'note_markdown.dart';

enum _AiPanelAction { summarize, polish, expand, title, translate, continueWrite, custom }

extension _AiPanelActionX on _AiPanelAction {
  String get api => switch (this) {
        _AiPanelAction.summarize => 'SUMMARIZE',
        _AiPanelAction.polish => 'POLISH',
        _AiPanelAction.expand => 'EXPAND',
        _AiPanelAction.title => 'TITLE',
        _AiPanelAction.translate => 'TRANSLATE',
        _AiPanelAction.continueWrite => 'CONTINUE',
        _AiPanelAction.custom => 'CUSTOM',
      };
  String get label => switch (this) {
        _AiPanelAction.summarize => 'note_ai.action_summarize'.tr(),
        _AiPanelAction.polish => 'note_ai.action_polish'.tr(),
        _AiPanelAction.expand => 'note_ai.action_expand'.tr(),
        _AiPanelAction.title => 'note_ai.action_title'.tr(),
        _AiPanelAction.translate => 'note_ai.action_translate'.tr(),
        _AiPanelAction.continueWrite => 'note_ai.action_continue'.tr(),
        _AiPanelAction.custom => 'note_ai.action_custom'.tr(),
      };
  List<List<dynamic>> get icon => switch (this) {
        _AiPanelAction.summarize => HugeIcons.strokeRoundedFileSearch,
        _AiPanelAction.polish => HugeIcons.strokeRoundedBrush,
        _AiPanelAction.expand => HugeIcons.strokeRoundedExpand,
        _AiPanelAction.title => HugeIcons.strokeRoundedText,
        _AiPanelAction.translate => HugeIcons.strokeRoundedTranslate,
        _AiPanelAction.continueWrite => HugeIcons.strokeRoundedPen01,
        _AiPanelAction.custom => HugeIcons.strokeRoundedMagicWand01,
      };
}

/// 右侧 AI 面板（与搜索面板互斥，仿 NoteSearchPanel 布局）
///
/// 宽度与搜索面板保持一致风格，包含：
/// - 动作选择（ChoiceChip）
/// - 翻译/自定义输入框
/// - 流式预览区
/// - 运行/应用结果按钮
class NoteAiPanel extends ConsumerStatefulWidget {
  const NoteAiPanel({
    super.key,
    required this.controller,
    required this.onClose,
    this.noteId,
    this.onTitle,
  });

  final QuillController controller;
  final VoidCallback onClose;
  final int? noteId;
  final ValueChanged<String>? onTitle;

  @override
  ConsumerState<NoteAiPanel> createState() => _NoteAiPanelState();
}

class _NoteAiPanelState extends ConsumerState<NoteAiPanel> {
  _AiPanelAction? _action;
  final _instructionCtrl = TextEditingController();

  /// 翻译目标语言（下拉选择，默认 English）
  String _targetLang = 'English';
  Timer? _uiThrottle;

  String _preview = '';
  bool _streaming = false;
  bool _failed = false;
  StreamSubscription<SseFrame>? _sub;

  int? _selStart;
  int? _selEnd;

  @override
  void dispose() {
    _unsub();
    _instructionCtrl.dispose();
    _uiThrottle?.cancel();
    super.dispose();
  }

  void _unsub() {
    _sub?.cancel();
    _sub = null;
  }

  String get _wholeMarkdown => deltaToMarkdown(widget.controller.document);

  String? _selectedPlainText() {
    final sel = widget.controller.selection;
    if (sel.start < 0 || sel.isCollapsed) return null;
    final plain = widget.controller.document.toPlainText();
    final start = sel.start.clamp(0, plain.length);
    final end = sel.end.clamp(0, plain.length);
    if (end <= start) return null;
    // 索引必须基于原始 toPlainText（嵌入占位符占位）计算，
    // 截取后再剔除 U+FFFC，避免把对象占位符发给 AI
    return plain.substring(start, end).replaceAll(
          Embed.kObjectReplacementCharacter,
          '',
        );
  }

  Map<String, dynamic> _buildRequest() {
    final action = _action!;
    final selected = _selectedPlainText()?.trim();
    String? effective;
    if (selected != null && selected.isNotEmpty) {
      effective = selected;
    } else {
      final whole = _wholeMarkdown.trim();
      if (whole.isNotEmpty) effective = whole;
    }
    return {
      'action': action.api,
      if (effective != null && effective.isNotEmpty)
        'content': effective
      else if (widget.noteId != null)
        'noteId': widget.noteId
      else
        'content': '',
      if (effective != null && effective.isNotEmpty && widget.noteId != null)
        'noteId': widget.noteId,
      if (action == _AiPanelAction.translate) 'targetLang': _targetLang,
      if (action == _AiPanelAction.custom && _instructionCtrl.text.trim().isNotEmpty)
        'instruction': _instructionCtrl.text.trim(),
    };
  }

  bool get _hasValidInput {
    final sel = _selectedPlainText()?.trim();
    if (sel != null && sel.isNotEmpty) return true;
    if (_wholeMarkdown.trim().isNotEmpty) return true;
    return widget.noteId != null;
  }

  void _start() {
    if (_action == null || _streaming) return;
    if (_action == _AiPanelAction.custom && _instructionCtrl.text.trim().isEmpty) {
      ref.read(toastServiceProvider).showToast('note_ai.instruction_required'.tr());
      return;
    }
    if (!_hasValidInput) {
      ref.read(toastServiceProvider).showToast('note_ai.empty_content'.tr());
      return;
    }

    final sel = widget.controller.selection;
    _selStart = (!sel.isCollapsed && sel.start >= 0) ? sel.start : null;
    _selEnd = (!sel.isCollapsed && sel.end >= 0) ? sel.end : null;

    setState(() {
      _preview = '';
      _failed = false;
      _streaming = true;
    });

    _unsub();
    var gotDone = false;
    _sub = SseClient.post('/note/ai/stream', body: _buildRequest()).listen(
      (frame) {
        if (!mounted) return;
        if (!frame.isNamed) {
          _preview += frame.data;
          _throttleUi();
          return;
        }
        switch (frame.event) {
          case 'done':
            gotDone = true;
            try {
              final json = jsonDecode(frame.data) as Map<String, dynamic>;
              final text = json['text'];
              if (text is String && text.isNotEmpty) _preview = text;
            } catch (_) {}
            setState(() => _streaming = false);
          case 'error':
            gotDone = true;
            setState(() {
              _streaming = false;
              _failed = true;
            });
            try {
              final json = jsonDecode(frame.data) as Map<String, dynamic>;
              ref.read(toastServiceProvider).showToast(
                    (json['message'] as String?) ?? 'note_ai.failed'.tr(),
                  );
            } catch (_) {
              ref.read(toastServiceProvider).showToast('note_ai.failed'.tr());
            }
        }
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _streaming = false;
          _failed = true;
        });
        String msg = 'note_ai.failed'.tr();
        if (e is DioException) {
          final err = e.error?.toString();
          if (err != null && err.isNotEmpty && !err.startsWith('SSE HTTP')) {
            msg = err;
          }
        }
        ref.read(toastServiceProvider).showToast(msg);
      },
      onDone: () {
        if (mounted && !gotDone && _streaming) {
          setState(() {
            _streaming = false;
            _failed = _preview.isEmpty;
          });
        }
      },
    );
  }

  void _throttleUi() {
    _uiThrottle?.cancel();
    _uiThrottle = Timer(const Duration(milliseconds: 80), () {
      if (mounted) setState(() {});
    });
  }

  void _applyReplaceAll() {
    final doc = markdownToDocument(_preview);
    widget.controller.document = doc;
  }

  void _applyAppendToEnd() {
    final combined = '${_wholeMarkdown.trimRight()}\n\n${_preview.trim()}';
    widget.controller.document = markdownToDocument(combined);
  }

  void _applyReplaceSelection() {
    final start = _selStart;
    final end = _selEnd;
    if (start == null || end == null || end <= start) {
      _applyReplaceAll();
      return;
    }
    // 结果经 Markdown→Delta 转换后整体插入，保留分割线等结构；
    // 之前直接插纯文本，会把 AI 输出里的 `---` 分割线原样留在正文里
    widget.controller.replaceText(
      start,
      end - start,
      _previewInsertionDelta(),
      const TextSelection.collapsed(offset: 0),
    );
  }

  /// 预览 Markdown 转为选区插入用的 Delta
  ///
  /// 去掉文档型 Delta 末尾的纯换行，避免替换选区后在下方多出一个空行；
  /// 带块级属性的换行（如标题结尾）保留，避免丢失格式。
  Delta _previewInsertionDelta() {
    final ops = markdownToDocument(_preview).toDelta().toList();
    if (ops.length > 1) {
      final last = ops.last;
      if (last.isInsert && last.data == '\n' && last.attributes == null) {
        ops.removeLast();
      }
    }
    final delta = Delta();
    for (final op in ops) {
      delta.push(op);
    }
    return delta;
  }

  void _applyAsTitle() {
    final t = _preview.trim().split('\n').first.trim();
    if (t.isEmpty) return;
    widget.onTitle?.call(t);
  }

  Future<void> _copyResult() async {
    await Clipboard.setData(ClipboardData(text: _preview));
    ref.read(toastServiceProvider).showToast('note_ai.copied'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasSelection = _selectedPlainText() != null;
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: .4),
        border: Border(
          left: BorderSide(color: cs.outlineVariant.withValues(alpha: .5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedSparkles, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('note_ai.title'.tr(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                if (hasSelection)
                  Text('note_ai.selection_scope'.tr(),
                      style: TextStyle(fontSize: 11, color: cs.primary)),
                IconButton(
                  tooltip: 'close'.tr(),
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onClose,
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: .5),
          // Content scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in _AiPanelAction.values)
                        ChoiceChip(
                          label: Text(a.label),
                          avatar: HugeIcon(
                              icon: a.icon,
                              size: 15,
                              color: _action == a ? cs.primary : cs.onSurfaceVariant),
                          selected: _action == a,
                          onSelected: _streaming ? null : (_) => setState(() => _action = a),
                        ),
                    ],
                  ),
                  if (_action == _AiPanelAction.custom) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _instructionCtrl,
                      enabled: !_streaming,
                      maxLines: 2,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'note_ai.instruction_hint'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (_action == _AiPanelAction.translate) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _targetLang,
                      isDense: true,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'note_ai.target_lang'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final lang in noteTranslateLangs)
                          DropdownMenuItem(value: lang, child: Text(lang)),
                      ],
                      // onChanged 为 null 时下拉框自动置灰
                      onChanged: _streaming
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _targetLang = value);
                            },
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildPreviewArea(cs),
                  const SizedBox(height: 12),
                  _buildActionsRow(cs),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(ColorScheme cs) {
    final empty = _preview.isEmpty;
    return Container(
      constraints: const BoxConstraints(minHeight: 120, maxHeight: 280),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
      ),
      child: empty && _streaming
          ? Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text('note_ai.generating'.tr(), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          : empty
              ? Center(
                  child: Text('note_ai.preview_empty'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                )
              : SingleChildScrollView(
                  child: SelectableText(_preview, style: Theme.of(context).textTheme.bodyMedium),
                ),
    );
  }

  Widget _buildActionsRow(ColorScheme cs) {
    final hasResult = _preview.isNotEmpty && !_streaming;
    final action = _action;
    if (_streaming) {
      return FilledButton.icon(
        onPressed: null,
        icon: HugeIcon(icon: HugeIcons.strokeRoundedLoading01, size: 16, color: cs.onSurface.withValues(alpha: .4)),
        label: Text('note_ai.generating'.tr()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: (_action == null || _streaming) ? null : _start,
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedPlay,
            size: 16,
            color: (_action == null) ? cs.onSurface.withValues(alpha: .4) : cs.onPrimary,
          ),
          label: Text('note_ai.run'.tr()),
        ),
        if (hasResult && action != null) ...[
          const SizedBox(height: 8),
          if (action == _AiPanelAction.title)
            FilledButton.tonal(onPressed: _applyAsTitle, child: Text('note_ai.use_as_title'.tr()))
          else ...[
            if ((action == _AiPanelAction.continueWrite || action == _AiPanelAction.expand) && _selStart == null)
              OutlinedButton(onPressed: _applyAppendToEnd, child: Text('note_ai.append'.tr())),
            const SizedBox(height: 8),
            if (_selStart != null &&
                (action == _AiPanelAction.polish ||
                    action == _AiPanelAction.translate ||
                    action == _AiPanelAction.custom))
              FilledButton(onPressed: _applyReplaceSelection, child: Text('note_ai.replace_selection'.tr()))
            else if (_selStart == null)
              FilledButton(onPressed: _applyReplaceAll, child: Text('note_ai.replace_all'.tr())),
          ],
          const SizedBox(height: 8),
          IconButton(
            tooltip: 'note_ai.copy'.tr(),
            onPressed: _copyResult,
            icon: HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 18, color: cs.onSurfaceVariant),
          ),
        ] else if (_failed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('note_ai.failed'.tr(), style: TextStyle(color: cs.error, fontSize: 12)),
          ),
      ],
    );
  }
}

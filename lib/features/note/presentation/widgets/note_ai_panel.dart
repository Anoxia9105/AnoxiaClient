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

import 'package:anoxia/common/widgets/ai_markdown_preview.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';

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
  String? _thinking;
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
      _thinking = null;
      _failed = false;
      _streaming = true;
    });

    _unsub();
    var gotDone = false;
    _sub = SseClient.post('/note/ai/stream', body: _buildRequest()).listen(
      (frame) {
        if (!mounted) return;
        if (!frame.isNamed) {
          if (_thinking != null) {
            setState(() => _thinking = null);
          }
          _preview += frame.data;
          _throttleUi();
          return;
        }
        switch (frame.event) {
          case 'thinking':
            setState(() => _thinking = frame.data == '[done]' ? null : (_thinking ?? '') + frame.data);
          case 'done':
            gotDone = true;
            try {
              final json = jsonDecode(frame.data) as Map<String, dynamic>;
              final text = json['text'];
              if (text is String && text.isNotEmpty) _preview = text;
            } catch (_) {}
            setState(() {
              _thinking = null;
              _streaming = false;
            });
          case 'error':
            gotDone = true;
            setState(() {
              _thinking = null;
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
            _thinking = null;
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
    final text = _preview.trim();
    if (text.isEmpty) return;
    final doc = widget.controller.document;
    // 空文档直接替换，避免开头多一个空行
    if (doc.toPlainText().trim().isEmpty) {
      widget.controller.document = markdownToDocument(text);
      return;
    }
    // 保留原文所有 Delta 格式，仅追加 AI 结果，避免整文 Markdown 往返导致的样式丢失
    final previewDelta = markdownToDocument(text).toDelta();
    final curDelta = doc.toDelta();
    final combined = Delta();
    for (final op in curDelta.toList()) {
      combined.push(op);
    }
    // 追加一个空行分隔（原文末尾自带 \n，再补一个 \n 形成空行）
    combined.insert('\n');
    for (final op in previewDelta.toList()) {
      combined.push(op);
    }
    widget.controller.document = Document.fromDelta(combined);
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
        color: cs.surfaceContainerLowest,
        border: Border(
          left: BorderSide(color: cs.outlineVariant.withValues(alpha: .5)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Polished header with subtle gradient and badge ---
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primaryContainer.withValues(alpha: .18),
                  cs.surfaceContainerLow.withValues(alpha: .0),
                ],
              ),
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: .5)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cs.primary.withValues(alpha: .18)),
                  ),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedSparkles, size: 16, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('note_ai.title'.tr(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -.2)),
                      if (hasSelection)
                        Text('note_ai.selection_scope'.tr(),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.primary)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'close'.tr(),
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onClose,
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 18, color: cs.onSurfaceVariant),
                  style: IconButton.styleFrom(
                    backgroundColor: cs.surfaceContainerHighest.withValues(alpha: .5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          // Content scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('AI 能力',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: .4, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in _AiPanelAction.values)
                        ChoiceChip(
                          label: Text(a.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                          avatar: HugeIcon(
                              icon: a.icon,
                              size: 14,
                              color: _action == a ? cs.onPrimaryContainer : cs.onSurfaceVariant),
                          selected: _action == a,
                          selectedColor: cs.primaryContainer,
                          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: .6),
                          side: BorderSide(
                              color: _action == a ? cs.primary.withValues(alpha: .4) : cs.outlineVariant.withValues(alpha: .6)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          showCheckmark: false,
                          onSelected: _streaming ? null : (_) => setState(() => _action = a),
                        ),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _action == _AiPanelAction.custom
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TextField(
                              key: const ValueKey('custom_field'),
                              controller: _instructionCtrl,
                              enabled: !_streaming,
                              maxLines: 3,
                              minLines: 2,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'note_ai.instruction_hint'.tr(),
                                hintStyle: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant.withValues(alpha: .7)),
                                filled: true,
                                fillColor: cs.surfaceContainerHighest.withValues(alpha: .5),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: .6))),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: cs.primary, width: 1.4)),
                              ),
                            ),
                          )
                        : _action == _AiPanelAction.translate
                            ? Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: DropdownButtonFormField<String>(
                                  key: const ValueKey('lang_field'),
                                  initialValue: _targetLang,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelText: 'note_ai.target_lang'.tr(),
                                    filled: true,
                                    fillColor: cs.surfaceContainerHighest.withValues(alpha: .5),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: .6))),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: cs.primary, width: 1.4)),
                                  ),
                                  items: [
                                    for (final lang in noteTranslateLangs)
                                      DropdownMenuItem(value: lang, child: Text(lang, style: const TextStyle(fontSize: 13))),
                                  ],
                                  onChanged: _streaming
                                      ? null
                                      : (value) {
                                          if (value == null) return;
                                          setState(() => _targetLang = value);
                                        },
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                  const SizedBox(height: 16),
                  _buildPreviewArea(cs),
                  const SizedBox(height: 16),
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
    final isStreaming = _streaming;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: cs.primary.withValues(alpha: .15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedEye, size: 12, color: cs.primary),
                  const SizedBox(width: 4),
                  Text('预览', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),

                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!isStreaming && !empty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${_preview.length} 字', style: TextStyle(fontSize: 10.5, color: cs.onTertiaryContainer)),
              ),
            const Spacer(),
            if (!empty)
              IconButton(
                tooltip: 'note_ai.copy'.tr(),
                visualDensity: VisualDensity.compact,
                onPressed: _copyResult,
                icon: HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 16, color: cs.onSurfaceVariant),
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHighest.withValues(alpha: .7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 140, maxHeight: 320),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: .45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: empty ? cs.outlineVariant.withValues(alpha: .35) : cs.primary.withValues(alpha: isStreaming ? .25 : .0),
                width: 1),
            boxShadow: empty
                ? null
                : [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: .06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: empty && isStreaming
                ? _buildSkeleton(cs, key: const ValueKey('generating'))
                : empty
                    ? Center(
                        key: const ValueKey('empty'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHigh,
                                shape: BoxShape.circle,
                                border: Border.all(color: cs.outlineVariant.withValues(alpha: .4)),
                              ),
                              child: HugeIcon(icon: HugeIcons.strokeRoundedSparkles, size: 22, color: cs.onSurfaceVariant.withValues(alpha: .6)),
                            ),
                            const SizedBox(height: 10),
                            Text('note_ai.preview_empty'.tr(),
                                style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('选择上方能力后点击运行',
                                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: .6))),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        key: ValueKey('content_${_preview.hashCode}'),
                        child: AiMarkdownPreview(data: _preview),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsRow(ColorScheme cs) {
    final hasResult = _preview.isNotEmpty && !_streaming;
    final action = _action;
    if (_streaming) {
      return SizedBox(
        height: 44,
        child: FilledButton.icon(
          onPressed: null,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            disabledBackgroundColor: cs.surfaceContainerHighest,
            disabledForegroundColor: cs.onSurfaceVariant,
          ),
          icon: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          ),
          label: Text('note_ai.generating'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 主运行按钮：更饱满、带光泽感
        SizedBox(
          height: 44,
          child: FilledButton.icon(
            onPressed: (_action == null) ? null : _start,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: _action == null ? 0 : 2,
              shadowColor: cs.primary.withValues(alpha: .35),
            ),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedSparkles,
              size: 16,
              color: (_action == null) ? cs.onSurface.withValues(alpha: .4) : cs.onPrimary,
            ),
            label: Text('note_ai.run'.tr(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: .2)),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: hasResult && action != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(height: 1, color: cs.outlineVariant.withValues(alpha: .4)),
                      const SizedBox(height: 12),
                      if (action == _AiPanelAction.title)
                        SizedBox(
                          height: 40,
                          child: FilledButton.tonalIcon(
                            onPressed: _applyAsTitle,
                            icon: HugeIcon(icon: HugeIcons.strokeRoundedText, size: 16, color: cs.primary),
                            label: Text('note_ai.use_as_title'.tr()),
                          ),
                        )
                      else ...[
                        if ((action == _AiPanelAction.continueWrite || action == _AiPanelAction.expand) && _selStart == null)
                          SizedBox(
                            height: 40,
                            child: OutlinedButton.icon(
                              onPressed: _applyAppendToEnd,
                              icon: HugeIcon(icon: HugeIcons.strokeRoundedNoteAdd, size: 16, color: cs.primary),
                              label: Text('note_ai.append'.tr()),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: BorderSide(color: cs.outlineVariant.withValues(alpha: .7)),
                              ),
                            ),
                          ),
                        if ((action == _AiPanelAction.continueWrite || action == _AiPanelAction.expand) && _selStart == null)
                          const SizedBox(height: 8),
                        if (_selStart != null &&
                            (action == _AiPanelAction.polish ||
                                action == _AiPanelAction.translate ||
                                action == _AiPanelAction.custom))
                          SizedBox(
                            height: 40,
                            child: FilledButton.icon(
                              onPressed: _applyReplaceSelection,
                              icon: HugeIcon(icon: HugeIcons.strokeRoundedRefresh01, size: 16, color: cs.onPrimary),
                              label: Text('note_ai.replace_selection'.tr()),
                              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            ),
                          )
                        else if (_selStart == null)
                          SizedBox(
                            height: 40,
                            child: FilledButton.icon(
                              onPressed: _applyReplaceAll,
                              icon: HugeIcon(icon: HugeIcons.strokeRoundedFileEdit, size: 16, color: cs.onPrimary),
                              label: Text('note_ai.replace_all'.tr()),
                              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            ),
                          ),
                      ],
                    ],
                  ),
                )
              : _failed
                  ? Padding(
                      key: const ValueKey('failed'),
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: cs.errorContainer.withValues(alpha: .6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.error.withValues(alpha: .3)),
                        ),
                        child: Row(
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedAlertCircle, size: 16, color: cs.error),
                            const SizedBox(width: 8),
                            Expanded(child: Text('note_ai.failed'.tr(), style: TextStyle(color: cs.error, fontSize: 12, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('idle')),
        ),
      ],
    );
  }

  Widget _buildSkeleton(ColorScheme cs, {Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLine(width: double.infinity, height: 12),
        const SizedBox(height: 10),
        const SkeletonLine(width: 220, height: 12),
        const SizedBox(height: 10),
        const SkeletonLine(width: 160, height: 12),
        const SizedBox(height: 16),
        const SkeletonLine(width: double.infinity, height: 12),
        const SizedBox(height: 10),
        const SkeletonLine(width: 190, height: 12),
        if (_thinking != null && _thinking!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(_thinking!,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: .6)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }
}

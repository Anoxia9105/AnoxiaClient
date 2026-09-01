/// 右侧 AI 面板（与搜索面板互斥，仿 NoteSearchPanel 布局）
///
/// 宽度与搜索面板保持一致风格，包含：
/// - 动作选择（ChoiceChip）
/// - 翻译/自定义输入框
/// - 流式预览区
/// - 运行/应用结果按钮
library;

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

import 'note_ai_panel_action.dart';
import 'note_ai_panel_widgets.dart';
import 'note_markdown.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

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
  AiPanelAction? _action;
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
      if (action == AiPanelAction.translate) 'targetLang': _targetLang,
      if (action == AiPanelAction.custom && _instructionCtrl.text.trim().isNotEmpty)
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
    if (_action == AiPanelAction.custom && _instructionCtrl.text.trim().isEmpty) {
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
              // 思考不算成功：无正文即失败
              _failed = _preview.isEmpty;
            });
            if (_preview.isEmpty) {
              ref.read(toastServiceProvider).showToast('note_ai.failed'.tr());
            }
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
                    borderRadius: BorderRadius.circular(RadiusToken.md),
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
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith( fontWeight: FontWeight.w800, letterSpacing: -.2)),
                      if (hasSelection)
                        Text('note_ai.selection_scope'.tr(),
                            style: Theme.of(context).textTheme.labelSmall!.copyWith( fontWeight: FontWeight.w500, color: cs.primary)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.md)),
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
                  NoteAiPanelActionSelector(
                    action: _action,
                    streaming: _streaming,
                    onSelected: (a) => setState(() => _action = a),
                    instructionCtrl: _instructionCtrl,
                    targetLang: _targetLang,
                    onLangChanged: (value) {
                      if (value == null) return;
                      setState(() => _targetLang = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  NoteAiPanelPreviewArea(
                    preview: _preview,
                    streaming: _streaming,
                    thinking: _thinking,
                    onCopy: _copyResult,
                  ),
                  const SizedBox(height: 16),
                  NoteAiPanelActionsRow(
                    preview: _preview,
                    streaming: _streaming,
                    failed: _failed,
                    action: _action,
                    selStart: _selStart,
                    onRun: _start,
                    onReplaceAll: _applyReplaceAll,
                    onAppendToEnd: _applyAppendToEnd,
                    onReplaceSelection: _applyReplaceSelection,
                    onApplyAsTitle: _applyAsTitle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

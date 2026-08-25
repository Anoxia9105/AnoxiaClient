/// 记事本 AI 面板（摘要/润色/扩写/标题/翻译/续写/自定义指令）
///
/// 交互流程：
/// 1. 选择动作（有选区时自动提示"仅处理选中文字"）→ 开始；
/// 2. 调用 POST /note/ai/stream，增量文本实时渲染到预览区；
/// 3. 完成后按动作提供：替换全文 / 追加到文末 / 设为标题 / 复制。
///
/// 结果不直接写入编辑器，统一经确认后落盘，避免与防抖自动保存冲突。
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

import 'package:anoxia/common/widgets/ai_markdown_preview.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';

import 'note_ai_langs.dart';
import 'note_markdown.dart';

enum _NoteAiAction { summarize, polish, expand, title, translate, continueWrite, custom }

extension _NoteAiActionX on _NoteAiAction {
  String get api => switch (this) {
        _NoteAiAction.summarize => 'SUMMARIZE',
        _NoteAiAction.polish => 'POLISH',
        _NoteAiAction.expand => 'EXPAND',
        _NoteAiAction.title => 'TITLE',
        _NoteAiAction.translate => 'TRANSLATE',
        _NoteAiAction.continueWrite => 'CONTINUE',
        _NoteAiAction.custom => 'CUSTOM',
      };

  String get label => switch (this) {
        _NoteAiAction.summarize => 'note_ai.action_summarize'.tr(),
        _NoteAiAction.polish => 'note_ai.action_polish'.tr(),
        _NoteAiAction.expand => 'note_ai.action_expand'.tr(),
        _NoteAiAction.title => 'note_ai.action_title'.tr(),
        _NoteAiAction.translate => 'note_ai.action_translate'.tr(),
        _NoteAiAction.continueWrite => 'note_ai.action_continue'.tr(),
        _NoteAiAction.custom => 'note_ai.action_custom'.tr(),
      };

  /// hugeicons 图标为路径数据，需配合 HugeIcon 组件使用
  List<List<dynamic>> get icon => switch (this) {
        _NoteAiAction.summarize => HugeIcons.strokeRoundedFileSearch,
        _NoteAiAction.polish => HugeIcons.strokeRoundedBrush,
        _NoteAiAction.expand => HugeIcons.strokeRoundedExpand,
        _NoteAiAction.title => HugeIcons.strokeRoundedText,
        _NoteAiAction.translate => HugeIcons.strokeRoundedTranslate,
        _NoteAiAction.continueWrite => HugeIcons.strokeRoundedPen01,
        _NoteAiAction.custom => HugeIcons.strokeRoundedMagicWand01,
      };
}

/// 打开记事本 AI 面板。
///
/// [onTitle] 用于 TITLE 动作把生成标题回填编辑器标题栏。
/// [noteId] 当前笔记ID，后端可在 content 为空时按 noteId 读取并校验归属，避免
/// 空内容触发 `noteId 与 content 至少提供一个` 错误；有选中文字或正文时会优先使用 content。
/// [initialAction] 预选动作（API 字符串：SUMMARIZE/POLISH/EXPAND/TITLE/TRANSLATE/CONTINUE/CUSTOM），
/// 用于工具栏气泡快捷入口直接选中对应动作。
Future<void> showNoteAiSheet(
  BuildContext context, {
  required QuillController controller,
  ValueChanged<String>? onTitle,
  int? noteId,
  String? initialAction,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _NoteAiSheet(
      controller: controller,
      onTitle: onTitle,
      noteId: noteId,
      initialAction: initialAction,
    ),
  );
}

class _NoteAiSheet extends ConsumerStatefulWidget {
  const _NoteAiSheet({
    required this.controller,
    this.onTitle,
    this.noteId,
    this.initialAction,
  });

  final QuillController controller;
  final ValueChanged<String>? onTitle;
  final int? noteId;
  final String? initialAction;

  @override
  ConsumerState<_NoteAiSheet> createState() => _NoteAiSheetState();
}

class _NoteAiSheetState extends ConsumerState<_NoteAiSheet> {
  _NoteAiAction? _action;
  final _instructionCtrl = TextEditingController();

  /// 翻译目标语言（下拉选择，默认 English）
  String _targetLang = 'English';
  Timer? _uiThrottle;

  @override
  void initState() {
    super.initState();
    final init = widget.initialAction;
    if (init != null) {
      for (final a in _NoteAiAction.values) {
        if (a.api == init) {
          _action = a;
          break;
        }
      }
    }
  }

  /// 流式预览文本
  String _preview = '';
  bool _streaming = false;
  bool _failed = false;
  String? _thinking;
  StreamSubscription<SseFrame>? _sub;

  /// 打开面板时捕获的选区（非折叠则仅处理选中文字）
  int? _selStart;
  int? _selEnd;

  @override
  void dispose() {
    _unsub();
    _instructionCtrl.dispose();
    super.dispose();
  }

  void _unsub() {
    _sub?.cancel();
    _sub = null;
  }

  // ---------------- 输入组装 ----------------

  String get _wholeMarkdown => deltaToMarkdown(widget.controller.document);

  /// 选区纯文本；无选区返回 null
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

  /// 组装请求体：优先使用选中文字，其次全文 Markdown；若均为空则改用 noteId 让后端读取
  Map<String, dynamic> buildRequest() {
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
        // 兜底：两者皆空时仍发送空 content，让后端返回明确错误（前端已提前拦截，此分支仅防御）
        'content': '',
      // 额外携带 noteId 作归属校验与日志关联（有 effective 时也一并带上，不影响后端优先使用 content）
      if (effective != null && effective.isNotEmpty && widget.noteId != null)
        'noteId': widget.noteId,
      if (action == _NoteAiAction.translate) 'targetLang': _targetLang,
      if (action == _NoteAiAction.custom && _instructionCtrl.text.trim().isNotEmpty)
        'instruction': _instructionCtrl.text.trim(),
    };
  }

  /// 当前是否有效可发送（至少 content 或 noteId 有一可用）
  bool get _hasValidInput {
    final sel = _selectedPlainText()?.trim();
    if (sel != null && sel.isNotEmpty) return true;
    if (_wholeMarkdown.trim().isNotEmpty) return true;
    return widget.noteId != null;
  }

  // ---------------- 流式调用 ----------------

  void _start() {
    if (_action == null || _streaming) return;
    if (_action == _NoteAiAction.custom && _instructionCtrl.text.trim().isEmpty) {
      ref.read(toastServiceProvider).showToast('note_ai.instruction_required'.tr());
      return;
    }
    if (!_hasValidInput) {
      ref.read(toastServiceProvider).showToast('note_ai.empty_content'.tr());
      return;
    }

    // 捕获当前选区
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
    _sub = SseClient.post('/note/ai/stream', body: buildRequest()).listen(
      (frame) {
        if (!mounted) return;
        if (!frame.isNamed) {
          // 匿名事件 = 增量文本；节流刷新 UI（同时清掉思考态）
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
            gotDone = true; // 结束流（按失败处理）
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
          } else if (e.response?.data != null) {
            try {
              // Dio 可能已将错误体解析为字符串
              final data = e.response?.data;
              if (data is String && data.isNotEmpty) {
                final j = jsonDecode(data);
                if (j is Map && j['message'] is String) msg = j['message'] as String;
              }
            } catch (_) {}
          }
          // 若仍为 generic，尝试从 error 中提取 JSON message
          if (msg == 'note_ai.failed'.tr() && e.error is String) {
            try {
              final j = jsonDecode(e.error as String);
              if (j is Map && j['message'] is String) msg = j['message'] as String;
            } catch (_) {
              final raw = e.error as String;
              if (raw.trim().isNotEmpty) msg = raw;
            }
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

  // ---------------- 结果应用 ----------------

  void _applyReplaceAll() {
    final doc = markdownToDocument(_preview);
    widget.controller.document = doc;
    Navigator.of(context).pop();
  }

  void _applyAppendToEnd() {
    final text = _preview.trim();
    if (text.isEmpty) return;
    final doc = widget.controller.document;
    if (doc.toPlainText().trim().isEmpty) {
      widget.controller.document = markdownToDocument(text);
      Navigator.of(context).pop();
      return;
    }
    final previewDelta = markdownToDocument(text).toDelta();
    final curDelta = doc.toDelta();
    final combined = Delta();
    for (final op in curDelta.toList()) {
      combined.push(op);
    }
    combined.insert('\n');
    for (final op in previewDelta.toList()) {
      combined.push(op);
    }
    widget.controller.document = Document.fromDelta(combined);
    Navigator.of(context).pop();
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
    Navigator.of(context).pop();
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
    Navigator.of(context).pop();
  }

  Future<void> _copyResult() async {
    await Clipboard.setData(ClipboardData(text: _preview));
    ref.read(toastServiceProvider).showToast('note_ai.copied'.tr());
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * .82,
        ),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedSparkles,
                  size: 18,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Text('note_ai.title'.tr(), style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (_selectedPlainText() != null)
                  Text('note_ai.selection_scope'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.primary)),
              ],
            ),
            const SizedBox(height: 12),
            Text('AI 能力',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: .4, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in _NoteAiAction.values)
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
              child: _action == _NoteAiAction.custom
                  ? Padding(
                      key: const ValueKey('custom_sheet'),
                      padding: const EdgeInsets.only(top: 12),
                      child: TextField(
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
                  : _action == _NoteAiAction.translate
                      ? Padding(
                          key: const ValueKey('lang_sheet'),
                          padding: const EdgeInsets.only(top: 12),
                          child: DropdownButtonFormField<String>(
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
                      : const SizedBox.shrink(key: ValueKey('empty_sheet')),
            ),
            const SizedBox(height: 16),
            _buildPreviewArea(cs),
            const SizedBox(height: 16),
            _buildActionsRow(cs),
          ],
        ),
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
          constraints: const BoxConstraints(minHeight: 140, maxHeight: 300),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: .45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: empty ? cs.outlineVariant.withValues(alpha: .35) : cs.primary.withValues(alpha: isStreaming ? .25 : .0)),
            boxShadow: empty
                ? null
                : [BoxShadow(color: cs.primary.withValues(alpha: .06), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: empty && isStreaming
                ? _buildSkeleton(cs, key: const ValueKey('gen_sheet'))
                : empty
                    ? Center(
                        key: const ValueKey('empty_sheet'),
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
                            Text('note_ai.preview_empty'.tr(), style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
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
          ),
          icon: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
          label: Text('note_ai.generating'.tr()),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                color: (_action == null) ? cs.onSurface.withValues(alpha: .4) : cs.onPrimary),
            label: Text('note_ai.run'.tr(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
                      if (action == _NoteAiAction.title)
                        SizedBox(
                          height: 40,
                          child: FilledButton.tonalIcon(
                            onPressed: _applyAsTitle,
                            icon: HugeIcon(icon: HugeIcons.strokeRoundedText, size: 16, color: cs.primary),
                            label: Text('note_ai.use_as_title'.tr()),
                          ),
                        )
                      else ...[
                        if ((action == _NoteAiAction.continueWrite || action == _NoteAiAction.expand) && _selStart == null)
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
                        if ((action == _NoteAiAction.continueWrite || action == _NoteAiAction.expand) && _selStart == null)
                          const SizedBox(height: 8),
                        if (_selStart != null &&
                            (action == _NoteAiAction.polish ||
                                action == _NoteAiAction.translate ||
                                action == _NoteAiAction.custom))
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
                      key: const ValueKey('failed_sheet'),
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
                            Expanded(child: Text('note_ai.failed'.tr(), style: TextStyle(color: cs.error, fontSize: 12))),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('idle_sheet')),
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
        const SkeletonLine(width: 240, height: 12),
        const SizedBox(height: 10),
        const SkeletonLine(width: 180, height: 12),
        const SizedBox(height: 16),
        const SkeletonLine(width: double.infinity, height: 12),
        const SizedBox(height: 10),
        const SkeletonLine(width: 200, height: 12),
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

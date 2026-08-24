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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

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
  final _langCtrl = TextEditingController(text: 'English');
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
  StreamSubscription<SseFrame>? _sub;

  /// 打开面板时捕获的选区（非折叠则仅处理选中文字）
  int? _selStart;
  int? _selEnd;

  @override
  void dispose() {
    _unsub();
    _instructionCtrl.dispose();
    _langCtrl.dispose();
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
    return plain.substring(start, end);
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
      if (action == _NoteAiAction.translate && _langCtrl.text.trim().isNotEmpty)
        'targetLang': _langCtrl.text.trim(),
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
      _failed = false;
      _streaming = true;
    });

    _unsub();
    var gotDone = false;
    _sub = SseClient.post('/note/ai/stream', body: buildRequest()).listen(
      (frame) {
        if (!mounted) return;
        if (!frame.isNamed) {
          // 匿名事件 = 增量文本；节流刷新 UI
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
            gotDone = true; // 结束流（按失败处理）
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
    // 全文 markdown + 结果整体重建，保留原格式
    final combined = '${_wholeMarkdown.trimRight()}\n\n${_preview.trim()}';
    widget.controller.document = markdownToDocument(combined);
    Navigator.of(context).pop();
  }

  void _applyReplaceSelection() {
    final start = _selStart;
    final end = _selEnd;
    if (start == null || end == null || end <= start) {
      _applyReplaceAll();
      return;
    }
    final plain = _stripHeavyMarkdown(_preview);
    widget.controller.replaceText(
        start, end - start, plain, const TextSelection.collapsed(offset: 0));
    Navigator.of(context).pop();
  }

  /// 选区替换走纯文本，剥离常见 Markdown 包装符号
  static String _stripHeavyMarkdown(String s) {
    return s
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\*\*|__|`'), '');
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in _NoteAiAction.values)
                  ChoiceChip(
                    label: Text(a.label),
                    avatar: HugeIcon(
                        icon: a.icon,
                        size: 15,
                        color: _action == a
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                    selected: _action == a,
                    onSelected: _streaming
                        ? null
                        : (_) => setState(() => _action = a),
                  ),
              ],
            ),
            if (_action == _NoteAiAction.custom) ...[
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
            if (_action == _NoteAiAction.translate) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _langCtrl,
                enabled: !_streaming,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'note_ai.target_lang'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildPreviewArea(cs),
            const SizedBox(height: 12),
            _buildActionsRow(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewArea(ColorScheme cs) {
    final empty = _preview.isEmpty;
    return Container(
      constraints: const BoxConstraints(minHeight: 120, maxHeight: 320),
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
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text('note_ai.generating'.tr(),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          : empty
              ? Center(
                  child: Text('note_ai.preview_empty'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                )
              : SingleChildScrollView(
                  child: SelectableText(
                    _preview,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
    );
  }

  Widget _buildActionsRow(ColorScheme cs) {
    final hasResult = _preview.isNotEmpty && !_streaming;
    final action = _action;
    return Row(
      children: [
        FilledButton.icon(
          onPressed: (_action == null || _streaming) ? null : _start,
          icon: HugeIcon(
            icon: _streaming
                ? HugeIcons.strokeRoundedLoading01
                : HugeIcons.strokeRoundedPlay,
            size: 16,
            color: (_action == null || _streaming)
                ? cs.onSurface.withValues(alpha: .4)
                : cs.onPrimary,
          ),
          label: Text(_streaming
              ? 'note_ai.generating'.tr()
              : 'note_ai.run'.tr()),
        ),
        const Spacer(),
        if (hasResult && action != null) ...[
          if (action == _NoteAiAction.title)
            FilledButton.tonal(
              onPressed: _applyAsTitle,
              child: Text('note_ai.use_as_title'.tr()),
            )
          else ...[
            if ((action == _NoteAiAction.continueWrite ||
                    action == _NoteAiAction.expand) &&
                _selStart == null)
              OutlinedButton(
                onPressed: _applyAppendToEnd,
                child: Text('note_ai.append'.tr()),
              ),
            const SizedBox(width: 8),
            if (_selStart != null &&
                (action == _NoteAiAction.polish ||
                    action == _NoteAiAction.translate ||
                    action == _NoteAiAction.custom))
              FilledButton(
                onPressed: _applyReplaceSelection,
                child: Text('note_ai.replace_selection'.tr()),
              )
            else if (_selStart == null)
              FilledButton(
                onPressed: _applyReplaceAll,
                child: Text('note_ai.replace_all'.tr()),
              ),
          ],
          IconButton(
            tooltip: 'note_ai.copy'.tr(),
            onPressed: _copyResult,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedCopy01,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
          ),
        ] else if (_failed)
          Text('note_ai.failed'.tr(),
              style: TextStyle(color: cs.error, fontSize: 12)),
      ],
    );
  }
}

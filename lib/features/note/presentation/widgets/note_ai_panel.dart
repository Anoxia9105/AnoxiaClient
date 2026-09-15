/// 记事本 AI 侧边栏（桌面端，与搜索面板互斥）
///
/// 结构与手机端弹框完全一致，只是换成并排容器：
/// 渐变头 → 作用范围分段控件 → 4 列能力网格 → 弹性预览 → 固定底栏。
/// 只有预览区随窗口高度伸缩，其余四段锁死，避免长结果把操作区顶走。
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

import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';

import 'ai/note_ai_capability_grid.dart';
import 'ai/note_ai_footer.dart';
import 'ai/note_ai_preview.dart';
import 'ai/note_ai_scope_bar.dart';
import 'note_ai_action.dart';
import 'note_markdown.dart';

/// 右侧 AI 侧边栏（与搜索面板互斥）
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

  /// 侧栏宽度：348 足以容纳 4 列能力格，并与左侧 240 的列表形成三段式
  static const double width = 348;

  @override
  ConsumerState<NoteAiPanel> createState() => _NoteAiPanelState();
}

class _NoteAiPanelState extends ConsumerState<NoteAiPanel> {
  NoteAiAction? _action;
  final _instructionCtrl = TextEditingController();

  /// 翻译目标语言（下拉选择，默认 English）
  String _targetLang = 'English';
  Timer? _uiThrottle;

  /// 作用范围：true = 整篇笔记，false = 仅选中文字
  late bool _whole;

  /// 打开面板时冻结的选区 / 全文字数，用于「作用范围」展示
  late final int _selectionChars;
  late final int _totalChars;

  String _preview = '';
  bool _streaming = false;
  bool _failed = false;
  String? _thinking;
  StreamSubscription<SseFrame>? _sub;

  int? _selStart;
  int? _selEnd;

  @override
  void initState() {
    super.initState();
    _selectionChars = (_selectedPlainText() ?? '').trim().length;
    _totalChars = _wholeMarkdown.trim().length;
    _whole = _selectionChars == 0;
  }

  @override
  void dispose() {
    _unsub();
    _uiThrottle?.cancel();
    _instructionCtrl.dispose();
    super.dispose();
  }

  void _unsub() {
    _sub?.cancel();
    _sub = null;
  }

  // ---------------- 输入组装 ----------------

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
    return plain
        .substring(start, end)
        .replaceAll(Embed.kObjectReplacementCharacter, '');
  }

  String? _effectiveContent() {
    if (!_whole) {
      final sel = _selectedPlainText()?.trim();
      if (sel != null && sel.isNotEmpty) return sel;
    }
    final whole = _wholeMarkdown.trim();
    return whole.isEmpty ? null : whole;
  }

  /// 结果是否可以「替换选中文字」（整篇模式下不适用）
  bool get _hasSelection => !_whole && _selectionChars > 0;

  Map<String, dynamic> _buildRequest() {
    final action = _action!;
    final effective = _effectiveContent();
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
      if (action == NoteAiAction.translate) 'targetLang': _targetLang,
      if (action == NoteAiAction.custom &&
          _instructionCtrl.text.trim().isNotEmpty)
        'instruction': _instructionCtrl.text.trim(),
    };
  }

  bool get _hasValidInput {
    if (_effectiveContent() != null) return true;
    return widget.noteId != null;
  }

  // ---------------- 流式调用 ----------------

  void _start() {
    if (_action == null || _streaming) return;
    if (_action == NoteAiAction.custom &&
        _instructionCtrl.text.trim().isEmpty) {
      ref
          .read(toastServiceProvider)
          .showToast('note_ai.instruction_required'.tr());
      return;
    }
    if (!_hasValidInput) {
      ref.read(toastServiceProvider).showToast('note_ai.empty_content'.tr());
      return;
    }

    final sel = widget.controller.selection;
    final canUseSelection = !sel.isCollapsed && sel.start >= 0;
    _selStart = _hasSelection && canUseSelection ? sel.start : null;
    _selEnd = _hasSelection && canUseSelection ? sel.end : null;

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
            setState(() => _thinking = frame.data == '[done]'
                ? null
                : (_thinking ?? '') + frame.data);
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

  /// 中断当前生成：保留已产出的部分结果，空结果按失败处理
  void _stop() {
    if (!_streaming) return;
    _unsub();
    setState(() {
      _thinking = null;
      _streaming = false;
      _failed = _preview.isEmpty;
    });
  }

  void _throttleUi() {
    _uiThrottle?.cancel();
    _uiThrottle = Timer(const Duration(milliseconds: 80), () {
      if (mounted) setState(() {});
    });
  }

  // ---------------- 结果应用 ----------------

  void _applyReplaceAll() {
    widget.controller.document = markdownToDocument(_preview);
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

  // ---------------- UI ----------------

  String get _statusText {
    if (_failed) return 'note_ai.failed'.tr();
    final label = _action?.label;
    if (_streaming && label != null) {
      return '${'note_ai.generating'.tr()} · $label';
    }
    if (_preview.isNotEmpty && label != null) {
      return '${'note_ai.status_done'.tr()} · $label';
    }
    if (label != null) {
      return '${'note_ai.status_selected'.tr()}「$label」';
    }
    return 'note_ai.choose_capability'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: NoteAiPanel.width,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(
          left: BorderSide(color: cs.outlineVariant.withValues(alpha: .5)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .20),
            blurRadius: 40,
            offset: const Offset(-16, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(cs),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingToken.lg,
                SpacingToken.lg,
                SpacingToken.lg,
                SpacingToken.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NoteAiScopeBar(
                    whole: _whole,
                    selectionChars: _selectionChars,
                    totalChars: _totalChars,
                    onChanged: _streaming
                        ? (_) {}
                        : (whole) => setState(() => _whole = whole),
                  ),
                  const SizedBox(height: SpacingToken.lg),
                  NoteAiCapabilityGrid(
                    action: _action,
                    enabled: !_streaming,
                    onSelected: (a) => setState(() => _action = a),
                    instructionCtrl: _instructionCtrl,
                    targetLang: _targetLang,
                    onLangChanged: (v) {
                      if (v == null) return;
                      setState(() => _targetLang = v);
                    },
                  ),
                  const SizedBox(height: SpacingToken.lg),
                  Expanded(
                    child: NoteAiPreview(
                      text: _preview,
                      streaming: _streaming,
                      thinking: _thinking,
                      onCopy: _copyResult,
                      onQuickPick: (a) => setState(() => _action = a),
                    ),
                  ),
                ],
              ),
            ),
          ),
          NoteAiFooter(
            preview: _preview,
            streaming: _streaming,
            failed: _failed,
            action: _action,
            hasSelection: _hasSelection,
            onRun: _start,
            onStop: _stop,
            onReplaceSelection: _applyReplaceSelection,
            onReplaceAll: _applyReplaceAll,
            onAppendToEnd: _applyAppendToEnd,
            onApplyAsTitle: _applyAsTitle,
            onCopy: _copyResult,
          ),
        ],
      ),
    );
  }

  /// 侧栏头部：渐变底 + 主色 logo 方块 + 标题/状态 + 收起/关闭
  Widget _buildHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        SpacingToken.lg,
        SpacingToken.md,
        SpacingToken.sm,
        SpacingToken.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: .17),
            cs.surfaceContainerLowest.withValues(alpha: 0),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: .5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(RadiusToken.md),
              boxShadow: [
                BoxShadow(
                  color: cs.primaryContainer.withValues(alpha: .40),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSparkles,
                size: 17,
                color: cs.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'note_ai.title'.tr(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.2,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  _statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10.5,
                        color: _failed ? cs.error : cs.primary,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'close'.tr(),
            visualDensity: VisualDensity.compact,
            onPressed: widget.onClose,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

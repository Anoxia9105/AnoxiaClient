/// 记事本 AI 底部弹出框（手机端）
///
/// 交互流程：
/// 1. 顶部「作用范围」分段控件确认 AI 读的是选中文字还是整篇；
/// 2. 在 4 列能力网格里选一个动作（自定义 / 翻译会就地展开附加输入）；
/// 3. 调 POST /note/ai/stream，增量文本实时渲染到预览区；生成中可随时「停止生成」；
/// 4. 完成后底栏主按钮变为当前动作的主去向（替换选中 / 替换全文 / 追加 / 设为标题）。
///
/// 结果不直接写入编辑器，统一经确认后落盘，避免与防抖自动保存冲突。
library;

import 'dart:async';
import 'dart:convert';

import 'package:anoxia/domain/ai_stream_event.dart';
import 'package:anoxia/framework/network/sse_client.dart';
import 'package:anoxia/framework/provider/ai/ai_feature_flags_provider.dart';
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
    backgroundColor: Colors.transparent,
    // 自绘抓取条 + 顶部圆角，交给 NoteAiSheet 统一处理
    showDragHandle: false,
    useSafeArea: true,
    builder: (_) => NoteAiSheet(
      controller: controller,
      onTitle: onTitle,
      noteId: noteId,
      initialAction: initialAction,
    ),
  );
}

class NoteAiSheet extends ConsumerStatefulWidget {
  const NoteAiSheet({
    super.key,
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
  ConsumerState<NoteAiSheet> createState() => NoteAiSheetState();
}

class NoteAiSheetState extends ConsumerState<NoteAiSheet> {
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

  /// 流式预览文本
  String _preview = '';
  bool _streaming = false;
  bool _failed = false;
  String? _thinking;
  StreamSubscription<SseFrame>? _sub;

  /// 开始生成时捕获的选区（非折叠则仅处理选中文字）
  int? _selStart;
  int? _selEnd;

  @override
  void initState() {
    super.initState();
    // 打开时冻结一次，避免用户切到整篇后字数展示跳变
    _selectionChars = (_selectedPlainText() ?? '').trim().length;
    _totalChars = _wholeMarkdown.trim().length;
    // 无选区时直接落在「整篇笔记」，不必先让用户点一次
    _whole = _selectionChars == 0;

    final init = widget.initialAction;
    if (init != null) {
      for (final a in NoteAiAction.values) {
        if (a.api == init) {
          _action = a;
          break;
        }
      }
    }
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
    return plain
        .substring(start, end)
        .replaceAll(Embed.kObjectReplacementCharacter, '');
  }

  /// 当前作用范围下真正要发给 AI 的文本；两边都空返回 null
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

  /// 组装请求体：按作用范围取文本；若均为空则改用 noteId 让后端读取
  Map<String, dynamic> buildRequest() {
    final action = _action!;
    final effective = _effectiveContent();
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
      if (action == NoteAiAction.translate) 'targetLang': _targetLang,
      if (action == NoteAiAction.custom &&
          _instructionCtrl.text.trim().isNotEmpty)
        'instruction': _instructionCtrl.text.trim(),
    };
  }

  /// 当前是否有效可发送（至少 content 或 noteId 有一可用）
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

    // 捕获当前选区（整篇模式下不需要）
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
              reportAiHealth(ref, false);
            } else {
              reportAiHealth(ref, true);
            }
          case 'error':
            gotDone = true; // 结束流（按失败处理）
            setState(() {
              _thinking = null;
              _streaming = false;
              _failed = true;
            });
            reportAiHealth(ref, false);
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
        reportAiHealth(ref, false);
        String msg = 'note_ai.failed'.tr();
        if (e is AiException) {
          if (e.message.isNotEmpty) msg = e.message;
        } else if (e is DioException) {
          final err = e.error?.toString();
          if (err != null && err.isNotEmpty && !err.startsWith('SSE HTTP')) {
            msg = err;
          } else if (e.response?.data != null) {
            try {
              // Dio 可能已将错误体解析为字符串
              final data = e.response?.data;
              if (data is String && data.isNotEmpty) {
                final j = jsonDecode(data);
                if (j is Map && j['message'] is String) {
                  msg = j['message'] as String;
                }
              }
            } catch (_) {}
          }
          // 若仍为 generic，尝试从 error 中提取 JSON message
          if (msg == 'note_ai.failed'.tr() && e.error is String) {
            try {
              final j = jsonDecode(e.error as String);
              if (j is Map && j['message'] is String) {
                msg = j['message'] as String;
              }
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
          // 断流兜底：有内容视为上游可达，无内容记一次失败
          reportAiHealth(ref, _preview.isNotEmpty);
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

  /// 头部状态文案：让用户随时知道「现在在做什么」
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
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final screenH = MediaQuery.sizeOf(context).height;
    // 键盘弹起时按剩余高度取 90%，避免底栏被挤到屏幕外
    final maxHeight = (screenH - keyboard) * .90;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: cs.primary.withValues(alpha: .20)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .45),
              blurRadius: 56,
              offset: const Offset(0, -22),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGrabHandle(cs),
            _buildHeader(cs),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: SpacingToken.lg),
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
                    const SizedBox(height: SpacingToken.lg),
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
            // 底部手势区留白，避免与系统 home indicator 贴合
            Container(
              width: 128,
              height: 5,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(RadiusToken.pill),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 自绘抓取条（showDragHandle 已关闭，避免与外层圆角打架）
  Widget _buildGrabHandle(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: cs.outlineVariant,
          borderRadius: BorderRadius.circular(RadiusToken.pill),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingToken.lg,
        2,
        SpacingToken.md,
        SpacingToken.md,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(RadiusToken.md),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSparkles,
                size: 16,
                color: cs.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'note_ai.title'.tr(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 14,
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
          _HeaderIconButton(
            icon: HugeIcons.strokeRoundedCancel01,
            tooltip: 'close'.tr(),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// 头部方形图标按钮
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusToken.md),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Center(
            child: HugeIcon(icon: icon, size: 17, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

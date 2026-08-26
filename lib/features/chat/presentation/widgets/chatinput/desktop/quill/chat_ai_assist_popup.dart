/// 桌面端输入框 AI 增强气泡（Notion 式结果卡）
///
/// 锚定工具栏 ✨ 按钮下方：
/// - 动作 chips：润色/扩写/续写/翻译▾/精简/自定义指令
/// - 内容源：quill 选区（优先）或全文；发起时快照，流式期间编辑不受影响
/// - 结果应用：替换选区 / 插入光标处 / 替换全文 + 重试 / 复制
library;

import 'package:anoxia/common/widgets/ai_markdown_preview.dart';
import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/note/presentation/widgets/note_markdown.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../ai/chat_ai_assist_core.dart';

const _translateLangs = <String>['中文', 'English', '日本語', '한국어', 'Français'];

/// 弹出输入框 AI 助手气泡（锚定按钮 context）
///
/// 会根据锚点按钮在屏幕中的位置自适应箭头方向：按钮靠近屏幕底部
/// （如桌面端输入栏）时气泡自动显示在按钮上方、箭头朝下，避免被
/// 屏幕底部或键盘遮挡。
void showChatAiAssistBubble(
  BuildContext anchorContext, {
  required QuillController controller,
  required FocusNode editorFocusNode,
}) {
  final colorScheme = Theme.of(anchorContext).colorScheme;
  final bubbleWidth = (MediaQuery.sizeOf(anchorContext).width - 24).clamp(
    280.0,
    420.0,
  );
  final screenSize = MediaQuery.sizeOf(anchorContext);
  Rect targetRect = Rect.fromLTWH(
    screenSize.width - 48,
    screenSize.height - 48,
    48,
    48,
  );
  try {
    final box = anchorContext.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final global = box.localToGlobal(Offset.zero);
      targetRect = global & box.size;
    }
  } catch (_) {}
  final placement = resolveAnchoredBubblePlacement(
    targetRect: targetRect,
    screenSize: screenSize,
    bubbleWidth: bubbleWidth,
    estimatedHeight: 380,
    preferRightArrow: true,
    arrowInset: 24,
    safeTop: MediaQuery.paddingOf(anchorContext).top,
  );
  BotToast.showEnhancedWidget(
    onlyOne: true,
    clickClose: true,
    ignoreContentClick: false,
    enableKeyboardSafeArea: false,
    backgroundColor: Colors.transparent,
    toastBuilder: (close) => Stack(
      children: [
        Positioned(
          left: placement.left,
          top: placement.showBelow ? placement.anchorY : null,
          bottom: placement.showBelow
              ? null
              : screenSize.height - placement.anchorY,
          width: bubbleWidth,
          child: Material(
            color: Colors.transparent,
            child: BubbleWidget(
              arrowDirection: placement.arrowDirection,
              arrowOffset: placement.arrowOffset,
              backgroundColor: colorScheme.surface,
              border: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: .8),
                width: .5,
              ),
              borderRadius: BorderRadius.circular(12),
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .16),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
              contentBuilder: (_) => ConstrainedBox(
                constraints: BoxConstraints(maxHeight: placement.maxHeight - 10),
                child: SingleChildScrollView(
                  child: ChatAiAssistCard(
                    controller: controller,
                    editorFocusNode: editorFocusNode,
                    onClose: close,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class ChatAiAssistCard extends StatefulWidget {
  const ChatAiAssistCard({
    super.key,
    required this.controller,
    required this.editorFocusNode,
    required this.onClose,
  });

  final QuillController controller;
  final FocusNode editorFocusNode;
  final VoidCallback onClose;

  @override
  State<ChatAiAssistCard> createState() => _ChatAiAssistCardState();
}

class _ChatAiAssistCardState extends State<ChatAiAssistCard> {
  final _core = ChatAiAssistCore();
  final _customCtrl = TextEditingController();

  ChatAiAction? _action;
  bool _showLangs = false;
  String _targetLang = 'English';

  /// 发起时快照：内容源与选区范围
  String _sourceText = '';
  int? _selStart;
  int? _selEnd;

  String _preview = '';
  String? _thinking;
  bool _streaming = false;
  bool _failed = false;
  String? _errorText;
  bool _copiedTick = false;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  @override
  void dispose() {
    _core.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  // ---------------- 内容源 ----------------

  ({String text, int? selStart, int? selEnd}) _captureSource() {
    final doc = widget.controller.document;
    final plain = doc.toPlainText();
    final sel = widget.controller.selection;
    final hasSel =
        sel.isValid && !sel.isCollapsed && sel.start >= 0 && sel.end <= plain.length;
    if (hasSel) {
      final text = plain.substring(sel.start, sel.end).trim();
      if (text.isNotEmpty) {
        return (text: text, selStart: sel.start, selEnd: sel.end);
      }
    }
    return (
      text: plain.trim(),
      selStart: null,
      selEnd: null,
    );
  }

  // ---------------- 流式调用 ----------------

  void _start(ChatAiAction action) {
    final src = _captureSource();
    if (src.text.isEmpty) {
      Toast.showToast('chat_ai.input_empty'.tr(), type: ToastType.warning);
      return;
    }
    if (action == ChatAiAction.custom &&
        _customCtrl.text.trim().isEmpty) {
      Toast.showToast('chat_ai.instruction_required'.tr(), type: ToastType.warning);
      return;
    }

    setState(() {
      _action = action;
      if (action == ChatAiAction.translate) _showLangs = !_showLangs;
      _sourceText = src.text;
      _selStart = src.selStart;
      _selEnd = src.selEnd;
      _preview = '';
      _thinking = null;
      _failed = false;
      _errorText = null;
      _streaming = true;
    });
    if (action != ChatAiAction.translate) _showLangs = false;

    _runTransform(action);
  }

  void _retry() {
    final action = _action;
    if (action == null || _streaming) return;
    setState(() {
      _preview = '';
      _thinking = null;
      _failed = false;
      _errorText = null;
      _streaming = true;
    });
    _runTransform(action);
  }

  void _runTransform(ChatAiAction action) {
    _core.transform(
      action: action,
      content: _sourceText,
      targetLang: _targetLang,
      customInstruction: _customCtrl.text.trim(),
      handlers: ChatAiStreamHandlers(
        onDelta: (fullText) {
          if (!mounted) return;
          setState(() => _preview = fullText);
        },
        onThinking: (thinking) {
          if (!mounted) return;
          setState(() => _thinking = thinking);
        },
        onDone: (_, fullText) {
          if (!mounted) return;
          setState(() {
            _preview = fullText;
            _thinking = null;
            _streaming = false;
          });
        },
        onError: (msg) {
          if (!mounted) return;
          setState(() {
            _thinking = null;
            _streaming = false;
            _failed = true;
            _errorText = msg;
          });
        },
      ),
    );
  }

  void mountedSetState() {
    if (!mounted) return;
    setState(() {});
  }

  // ---------------- 应用结果 ----------------

  /// 预览 Markdown 转为插入用的 Delta（去掉末尾纯换行，避免多出空行）
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

  int _deltaLength(Delta delta) {
    var len = 0;
    for (final op in delta.toList()) {
      final data = op.data;
      if (data is String) {
        len += data.length;
      } else {
        len += 1;
      }
    }
    return len;
  }

  void _applyToSelection() {
    final s = _selStart;
    final e = _selEnd;
    if (s == null || e == null || e <= s || _preview.isEmpty) {
      return;
    }
    final delta = _previewInsertionDelta();
    if (delta.isEmpty) {
      return;
    }
    widget.controller.replaceText(
      s,
      e - s,
      delta,
      TextSelection.collapsed(offset: s + _deltaLength(delta)),
    );
    _finishApply();
  }

  void _insertAtCursor() {
    if (_preview.isEmpty) {
      return;
    }
    final delta = _previewInsertionDelta();
    if (delta.isEmpty) {
      return;
    }
    final base = widget.controller.selection.baseOffset;
    final docLen = widget.controller.document.length;
    final offset = (base < 0 || base > docLen) ? docLen - 1 : base;
    // 若原文为空文档长度为1（仅含末尾换行），插入到0更符合追加到文末的预期
    final insertAt = docLen <= 1 ? 0 : offset;
    widget.controller.replaceText(
      insertAt,
      0,
      delta,
      TextSelection.collapsed(offset: insertAt + _deltaLength(delta)),
    );
    _finishApply();
  }

  void _replaceAll() {
    if (_preview.isEmpty) {
      return;
    }
    widget.controller.document = markdownToDocument(_preview);
    _finishApply();
  }

  void _finishApply() {
    widget.onClose();
    widget.editorFocusNode.requestFocus();
  }

  Future<void> _copyPreview() async {
    if (_preview.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _preview));
    if (!mounted) return;
    setState(() => _copiedTick = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _copiedTick = false);
    });
  }

  bool get _hasSelectionRange => _selStart != null && _selEnd != null;

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildActionChips(),
          if (_showLangs) ...[
            const SizedBox(height: 6),
            _buildLangChips(),
          ],
          if (_action == ChatAiAction.custom) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _customCtrl,
                    enabled: !_streaming,
                    maxLines: 2,
                    minLines: 1,
                    style: const TextStyle(fontSize: 12.5),
                    onSubmitted: (_) => _start(ChatAiAction.custom),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'chat_ai.custom_hint'.tr(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: _streaming ? null : () => _start(ChatAiAction.custom),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('note_ai.run'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _buildPreviewArea(),
          if (_failed && _errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_errorText!,
                  style: TextStyle(fontSize: 11.5, color: _cs.error)),
            ),
          if (_hasResult) ...[
            const SizedBox(height: 8),
            _buildApplyRow(),
          ],
        ],
      ),
    );
  }

  bool get _hasResult => _preview.isNotEmpty && !_streaming;

  Widget _buildHeader() {
    final scope = _hasSelectionRange && _sourceText.isNotEmpty
        ? 'chat_ai.scope_selection'.tr()
        : 'chat_ai.scope_all'.tr();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cs.primaryContainer.withValues(alpha: .18), _cs.surfaceContainerLow.withValues(alpha: 0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cs.outlineVariant.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _cs.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: HugeIcon(icon: HugeIcons.strokeRoundedSparkles, size: 14, color: _cs.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('chat_ai.assist_title'.tr(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -.2)),
                Text(scope, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: _cs.primary)),
              ],
            ),
          ),
          _iconBtn(HugeIcons.strokeRoundedCancel01, 'close'.tr(), widget.onClose),
        ],
      ),
    );
  }

  Widget _buildActionChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _chip('chat_ai.polish'.tr(), _streaming ? null : () => _start(ChatAiAction.polish),
            selected: _action == ChatAiAction.polish),
        _chip('chat_ai.expand'.tr(), _streaming ? null : () => _start(ChatAiAction.expand),
            selected: _action == ChatAiAction.expand),
        _chip('chat_ai.continue'.tr(), _streaming ? null : () => _start(ChatAiAction.continueWrite),
            selected: _action == ChatAiAction.continueWrite),
        _chip('chat_ai.translate'.tr(), _streaming ? null : () => _start(ChatAiAction.translate),
            selected: _action == ChatAiAction.translate),
        _chip('chat_ai.simplify'.tr(), _streaming ? null : () => _start(ChatAiAction.simplify),
            selected: _action == ChatAiAction.simplify),
        _chip(
          'chat_ai.custom'.tr(),
          _streaming
              ? null
              : () {
                  setState(() {
                    _action = ChatAiAction.custom;
                    _showLangs = false;
                  });
                },
          selected: _action == ChatAiAction.custom,
        ),
      ],
    );
  }

  Widget _buildLangChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final lang in _translateLangs)
          _chip(
            lang,
            () => setState(() => _targetLang = lang),
            selected: _targetLang == lang,
          ),
      ],
    );
  }

  Widget _chip(String label, VoidCallback? onTap, {bool selected = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      hoverColor: _cs.primary.withValues(alpha: .08),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? _cs.primaryContainer.withValues(alpha: .6) : null,
          border: Border.all(
            color: selected
                ? _cs.primary.withValues(alpha: .5)
                : _cs.outlineVariant.withValues(alpha: .7),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? _cs.primary : _cs.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewArea() {
    final empty = _preview.isEmpty && !_streaming;
    final isStreaming = _streaming;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _cs.primaryContainer.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedEye, size: 11, color: _cs.primary),
                  const SizedBox(width: 4),
                  Text('预览', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _cs.primary)),
                ],
              ),
            ),
            const Spacer(),
            if (!empty)
              InkWell(
                onTap: _copyPreview,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 14, color: _cs.onSurfaceVariant),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 56, maxHeight: 240),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _cs.surfaceContainerHighest.withValues(alpha: .45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: empty ? _cs.outlineVariant.withValues(alpha: .5) : _cs.primary.withValues(alpha: .18)),
            boxShadow: empty ? null : [BoxShadow(color: _cs.primary.withValues(alpha: .06), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: empty
                ? Center(
                    key: const ValueKey('empty_chat'),
                    child: Text('chat_ai.preview_empty'.tr(),
                        style: TextStyle(fontSize: 11.5, color: _cs.onSurfaceVariant), textAlign: TextAlign.center),
                  )
                : isStreaming && _preview.isEmpty
                    ? _buildSkeleton(key: const ValueKey('streaming'))
                    : SingleChildScrollView(
                        key: ValueKey('content_${_preview.hashCode}'),
                        child: AiMarkdownPreview(data: _preview),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLine(width: double.infinity, height: 11),
        const SizedBox(height: 8),
        const SkeletonLine(width: 200, height: 11),
        const SizedBox(height: 8),
        const SkeletonLine(width: 160, height: 11),
        const SizedBox(height: 12),
        const SkeletonLine(width: double.infinity, height: 11),
        const SizedBox(height: 8),
        const SkeletonLine(width: 180, height: 11),
        if (_thinking != null && _thinking!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_thinking!,
              style: TextStyle(fontSize: 10.5, color: _cs.onSurfaceVariant.withValues(alpha: .6)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }

  Widget _buildApplyRow() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_hasSelectionRange)
          _applyBtn('chat_ai.replace_selection'.tr(), _applyToSelection, filled: true)
        else ...[
          _applyBtn('chat_ai.insert_cursor'.tr(), _insertAtCursor, filled: true),
          _applyBtn('chat_ai.replace_all'.tr(), _replaceAll),
        ],
        _applyBtn('chat_ai.retry'.tr(), _retry),
        _miniIconBtn(
          _copiedTick ? HugeIcons.strokeRoundedTick02 : HugeIcons.strokeRoundedCopy01,
          'chat_ai.copy'.tr(),
          _copyPreview,
        ),
      ],
    );
  }

  Widget _applyBtn(String label, VoidCallback onTap, {bool filled = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? _cs.primary : _cs.surfaceContainerHighest.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: filled ? _cs.onPrimary : _cs.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _miniIconBtn(List<List<dynamic>> icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: HugeIcon(icon: icon, size: 14, color: _cs.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _iconBtn(List<List<dynamic>> icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: HugeIcon(icon: icon, size: 14, color: _cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

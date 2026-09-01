/// 移动端输入框 AI 助手面板
///
/// 挂载在 ChatBottomPanelContainer 的 `ai` 面板类型：
/// - 内容源：输入框选区（优先）或全文
/// - 动作 chips：润色/扩写/续写/翻译▾/精简/自定义指令
/// - 结果应用：替换选区 / 插入光标 / 替换全文 + 重试 / 复制
library;

import 'package:anoxia/common/widgets/ai_markdown_preview.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/provider/chat/input/mobile_text_input_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../ai/chat_ai_assist_core.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

const _translateLangs = <String>['中文', 'English', '日本語', '한국어', 'Français'];

class MobileChatAiPanel extends StatefulWidget {
  const MobileChatAiPanel({
    super.key,
    required this.inputController,
    required this.onClose,
  });

  final MobileTextInputController inputController;
  final VoidCallback onClose;

  @override
  State<MobileChatAiPanel> createState() => _MobileChatAiPanelState();
}

class _MobileChatAiPanelState extends State<MobileChatAiPanel> {
  final _core = ChatAiAssistCore();
  final _customCtrl = TextEditingController();

  ChatAiAction? _action;
  bool _showLangs = false;
  String _targetLang = 'English';

  String _sourceText = '';
  int? _selStart;
  int? _selEnd;

  String _preview = '';
  String? _thinking;
  bool _streaming = false;
  bool _failed = false;
  String? _errorText;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  @override
  void dispose() {
    _core.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  // ---------------- 内容源 ----------------

  ({String text, int? selStart, int? selEnd}) _captureSource() {
    final tc = widget.inputController.textController;
    final text = tc.text;
    final sel = tc.selection;
    final hasSel =
        sel.isValid && !sel.isCollapsed && sel.start >= 0 && sel.end <= text.length;
    if (hasSel) {
      final picked = text.substring(sel.start, sel.end).trim();
      if (picked.isNotEmpty) {
        return (text: picked, selStart: sel.start, selEnd: sel.end);
      }
    }
    return (text: text.trim(), selStart: null, selEnd: null);
  }

  // ---------------- 流式调用 ----------------

  void _start(ChatAiAction action) {
    final src = _captureSource();
    if (src.text.isEmpty) {
      Toast.showToast('chat_ai.input_empty'.tr(), type: ToastType.warning);
      return;
    }
    if (action == ChatAiAction.custom && _customCtrl.text.trim().isEmpty) {
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

  // ---------------- 应用结果（纯文本回填） ----------------

  bool get _hasSelectionRange => _selStart != null && _selEnd != null;

  /// 原子写回：value= 保证文本与光标一致更新；mention 高亮等富文本样式不保留
  void _writeBack(String newText, int cursorOffset) {
    widget.inputController.textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }

  void _applyToSelection() {
    final s = _selStart;
    final e = _selEnd;
    if (s == null || e == null || e <= s || _preview.isEmpty) return;
    final current = widget.inputController.textController.text;
    // 选区快照后用户可能又编辑过，越界则放弃替换
    if (e > current.length) return;
    final combined =
        current.substring(0, s) + _preview + current.substring(e);
    _writeBack(combined, s + _preview.length);
    widget.onClose();
  }

  void _insertAtCursor() {
    if (_preview.isEmpty) return;
    final tc = widget.inputController.textController;
    var offset = tc.selection.baseOffset;
    if (offset < 0 || offset > tc.text.length) offset = tc.text.length;
    final combined =
        tc.text.substring(0, offset) + _preview + tc.text.substring(offset);
    _writeBack(combined, offset + _preview.length);
    widget.onClose();
  }

  void _replaceAll() {
    if (_preview.isEmpty) return;
    _writeBack(_preview, _preview.length);
    widget.onClose();
  }

  Future<void> _copyPreview() async {
    if (_preview.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _preview));
    if (mounted) Toast.showToast('chat_ai.copied'.tr(), type: ToastType.success);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                            style: const TextStyle(fontSize: 12),
                            onSubmitted: (_) => _start(ChatAiAction.custom),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'chat_ai.custom_hint'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(RadiusToken.md),
                              ),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.md)),
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
                      child:
                          Text(_errorText!, style: TextStyle(fontSize: 12, color: _cs.error)),
                    ),
                  if (_preview.isNotEmpty && !_streaming) ...[
                    const SizedBox(height: 8),
                    _buildApplyRow(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(color: _cs.outlineVariant.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _cs.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(RadiusToken.md),
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
                Text(scope, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _cs.primary)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'close'.tr(),
            visualDensity: VisualDensity.compact,
            onPressed: widget.onClose,
            icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16, color: _cs.onSurfaceVariant),
            style: IconButton.styleFrom(
              backgroundColor: _cs.surfaceContainerHighest.withValues(alpha: .6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.md)),
            ),
          ),
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
      borderRadius: BorderRadius.circular(RadiusToken.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusToken.pill),
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
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? _cs.primary : _cs.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewArea() {
    final empty = _preview.isEmpty && !_streaming;
    return Container(
      constraints: const BoxConstraints(minHeight: 56, maxHeight: 260),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cs.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(color: _cs.outlineVariant.withValues(alpha: .5)),
      ),
      child: empty
          ? Center(
              child: Text('chat_ai.preview_empty'.tr(),
                  style: TextStyle(fontSize: 12, color: _cs.onSurfaceVariant),
                  textAlign: TextAlign.center))
          : _streaming && _preview.isEmpty
              ? _buildSkeleton()
              : SingleChildScrollView(
                  child: AiMarkdownPreview(data: _preview),
                ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
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
              style: TextStyle(fontSize: 11, color: _cs.onSurfaceVariant.withValues(alpha: .6)),
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
      children: [
        if (_hasSelectionRange)
          _applyBtn('chat_ai.replace_selection'.tr(), _applyToSelection, filled: true)
        else ...[
          _applyBtn('chat_ai.insert_cursor'.tr(), _insertAtCursor, filled: true),
          _applyBtn('chat_ai.replace_all'.tr(), _replaceAll),
        ],
        _applyBtn('chat_ai.retry'.tr(), _retry),
        _applyBtn('chat_ai.copy'.tr(), _copyPreview),
      ],
    );
  }

  Widget _applyBtn(String label, VoidCallback onTap, {bool filled = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusToken.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? _cs.primary : _cs.surfaceContainerHighest.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(RadiusToken.md),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: filled ? _cs.onPrimary : _cs.onSurface,
          ),
        ),
      ),
    );
  }
}
